package aria.neko.box

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 应用主入口：处理常规启动 + 四种分享入口（文本选择/文本分享/媒体分享/otpauth 链接）。
 *
 * 通道设计：
 *   - MethodChannel("neko.box/share"): Flutter call getInitialShare() 拿冷启动数据
 *                                        persistUri() 把 content:// 持久化到本地
 *   - EventChannel("neko.box/share/events"): 推送给 Flutter 的 SEND/SEND_MULTIPLE/PROCESS_TEXT/VIEW TOTP 事件
 *
 * 数据契约（传给 Dart 的 Map）：
 *   action: "process_text" | "send_text" | "send_file" | "send_multiple" | "view_totp"
 *   各 action 对应的键见 ShareReceiverHelper.parse()。
 */
class MainActivity : FlutterActivity() {

    private val methodChannelName = "neko.box/share"
    private val eventChannelName = "neko.box/share/events"

    // 第一次冷启动的 INTENT 被解析后暂存于此；Flutter 就绪后取走。
    private var pendingShareEvent: Map<String, Any?>? = null

    // 冷启动时收到的桌面快捷方式 deep link intent（ACTION_VIEW + nekobox://…），取走后清零。
    private var deepLinkIntent: Intent? = null

    private var shareEventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppContextResolver.resolver = contentResolver
        AppContextResolver.cacheDir = cacheDir
        // 解析冷启动 intent
        pendingShareEvent = ShareReceiverHelper.parse(intent)
        // 捕获桌面快捷方式的 deep link（ACTION_VIEW with data URI）
        if (intent?.action == Intent.ACTION_VIEW && intent?.data != null) {
            deepLinkIntent = intent
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel: Dart 侧 getInitialShare() / persistUri() / createDesktopShortcut()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        val event = pendingShareEvent
                        pendingShareEvent = null
                        result.success(event)
                    }
                    "persistUri" -> {
                        val uriStr = call.argument<String>("uri")
                        val suggestedName = call.argument<String>("suggestedName")
                        if (uriStr.isNullOrEmpty()) {
                            result.error("EINVAL", "uri 为空", null)
                        } else {
                            try {
                                val uri = android.net.Uri.parse(uriStr)
                                val path = ShareReceiverHelper.persistUri(uri, suggestedName)
                                if (path != null) {
                                    result.success(path)
                                } else {
                                    result.error("EIO", "持久化失败", null)
                                }
                            } catch (e: Exception) {
                                result.error("EEXCEPTION", e.message, null)
                            }
                        }
                    }
                    "createDesktopShortcut" -> {
                        val memoId = call.argument<String>("memoId")
                        val memoType = call.argument<String>("memoType")
                        val shortcutTitle = call.argument<String>("title")
                        val iconBytes = call.argument<ByteArray>("iconBytes")
                        val bgColor = call.argument<Int>("bgColor")
                        if (memoId.isNullOrEmpty() || shortcutTitle.isNullOrEmpty()) {
                            result.error("EINVAL", "memoId 或 title 为空", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val ok = installDesktopShortcut(
                                memoId = memoId,
                                memoType = memoType ?: "text",
                                title = shortcutTitle,
                                iconBytes = iconBytes,
                                bgColor = bgColor,
                            )
                            result.success(ok)
                        } catch (e: Exception) {
                            result.error("EEXCEPTION", e.message, null)
                        }
                    }
                    "getInitialDeepLink" -> {
                        val deepLink = consumeInitialDeepLink()
                        result.success(deepLink)
                    }
                    "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                    else -> result.notImplemented()
                }
            }

        // EventChannel: 推送给 Dart
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    shareEventSink = events
                    // 如果 Flutter 开始监听时已有缓存事件（极少见，保险起见），立刻推出。
                    pendingShareEvent?.let {
                        success(it)
                        pendingShareEvent = null
                    }
                }
                override fun onCancel(arguments: Any?) {
                    shareEventSink = null
                }
            })
    }

    private fun success(event: Map<String, Any?>?) {
        try {
            shareEventSink?.success(event)
        } catch (_: Exception) { /* sink closed */ }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // 热启动 deep link（桌面快捷方式打开）→ 让 Flutter 取走
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            deepLinkIntent = intent
        }
        val event = ShareReceiverHelper.parse(intent)
        if (event != null) {
            // App 在后台 / 前台，通过 EventChannel 推送
            success(event)
        }
    }

    override fun onDestroy() {
        shareEventSink = null
        super.onDestroy()
    }

    /**
     * 由 Flutter 冷启动时调用：取走暂存的 deep link 信息。
     * 返回 Map： { "uri": "nekobox://memo/text/abc123" } 或 null。
     */
    private fun consumeInitialDeepLink(): Map<String, Any?>? {
        val intent = deepLinkIntent ?: return null
        deepLinkIntent = null
        val data = intent.data ?: return null
        return mapOf("uri" to data.toString())
    }
}

/**
 * 为用户在桌面创建 Reign（铭记）快捷方式。
 *
 * - 点击快捷方式：打开 MainActivity，带上 memoId + memoType 的 deep link，
 *   Flutter 侧根据路由直接打开对应铭记。
 * - 图标：优先使用传入的 iconBytes；为 null 时使用首字符位图（带背景色方块）。
 *
 * 仅 Android 8.0+（API 26+）支持 requestPinShortcut，本次工程 minSdk 刚好 26。
 */
private fun MainActivity.installDesktopShortcut(
    memoId: String,
    memoType: String,
    title: String,
    iconBytes: ByteArray?,
    bgColor: Int?,
): Boolean {
    val context = this
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false

    if (!ShortcutManagerCompat.isRequestPinShortcutSupported(context)) return false

    // deep link URI → nekobox://memo/{type}/{id}
    val deepLink = Uri.parse("nekobox://memo/$memoType/$memoId")
    val intent = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_VIEW
        data = deepLink
        putExtra("shortcut_memo_id", memoId)
        putExtra("shortcut_memo_type", memoType)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    // 构造图标
    val icon: IconCompat = if (iconBytes != null && iconBytes.isNotEmpty()) {
        try {
            val bmp = android.graphics.BitmapFactory.decodeByteArray(iconBytes, 0, iconBytes.size)
            if (bmp != null) IconCompat.createWithBitmap(bmp) else buildTextIcon(title, bgColor)
        } catch (_: Exception) {
            buildTextIcon(title, bgColor)
        }
    } else {
        buildTextIcon(title, bgColor)
    }

    val shortcut = ShortcutInfoCompat.Builder(context, "memo_shortcut_$memoId")
        .setShortLabel(title)
        .setLongLabel(title)
        .setIcon(icon)
        .setIntent(intent)
        .build()

    return try {
        ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)
    } catch (_: Exception) {
        false
    }
}

/**
 * 用铭记标题第一个字符生成带彩色背景的圆形图标位图。
 * 首字符取第一个非空白字符；bgColor 为 null 时使用品牌紫 #6750A4。
 */
private fun buildTextIcon(title: String, bgColor: Int?): IconCompat {
    val size = 108 // dp 密度无关
    val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bmp)

    // 背景圆
    val bg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = bgColor ?: Color.parseColor("#6750A4")
        style = Paint.Style.FILL
    }
    canvas.drawCircle(size / 2f, size / 2f, size / 2f, bg)

    // 首字符（取第一个非空白字符，若无则用"铭"）
    val ch = title.firstOrNull { !it.isWhitespace() } ?: '铭'
    val text = ch.toString().let { if (it.matches(Regex("[a-zA-Z]"))) it.uppercase() else it }

    val fg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
        textSize = size * 0.5f
        isFakeBoldText = true
    }
    val metrics = fg.fontMetrics
    val baseline = size / 2f - (metrics.ascent + metrics.descent) / 2f
    canvas.drawText(text, size / 2f, baseline, fg)

    return IconCompat.createWithBitmap(bmp)
}
