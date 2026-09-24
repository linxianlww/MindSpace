package aria.neko.box

import android.app.Activity
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import aria.neko.box.widget.WidgetChannelRegistrar
import aria.neko.box.widget.WidgetClickBus
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 应用主入口：处理常规启动 + 四种分享入口（文本选择/文本分享/媒体分享/otpauth 链接）+ 桌面小组件回调。
 *
 * 通道设计：
 *   - MethodChannel("neko.box/share"): Flutter call getInitialShare() 拿冷启动数据
 *                                        persistUri() 把 content:// 持久化到本地
 *   - EventChannel("neko.box/share/events"): 推送给 Flutter 的 SEND/SEND_MULTIPLE/PROCESS_TEXT/VIEW TOTP 事件
 *   - MethodChannel("neko.box/widget"): Flutter call saveWidgetData() 写入小组件显示数据
 *                                         updateWidget() 触发小组件界面刷新
 *                                         getInitialWidgetData() 获取当前小组件数据
 *                                         registerDeepLinkListener() 注册小组件点击监听
 *   - EventChannel("neko.box/widget/events"): 推送给 Flutter 的点击事件（URI）
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

    // 私密空间：系统 Pin 验证等待中的 Result（防止并发重复调用）。
    private var securePinResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        AppContextResolver.resolver = contentResolver
        AppContextResolver.cacheDir = cacheDir
        // 解析冷启动 intent（注入 targetFolderId 若存在）
        pendingShareEvent = ShareReceiverHelper.parse(intent)
        // 捕获桌面快捷方式或小组件的 deep link（ACTION_VIEW with data URI）
        if (intent?.action == Intent.ACTION_VIEW && intent?.data != null) {
            val uri = intent.data
            if (uri?.host == "widget") {
                // 小组件点击事件 → 暂存供 Flutter 取走（EventChannel 就绪后自动推出）
                WidgetClickBus.post(uri.toString())
            } else {
                // 桌面快捷方式等普通 deep link
                deepLinkIntent = intent
            }
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

        // 私密空间：截屏保护 FLAG_SECURE 控制
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "neko.box/secure_flags")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "enableSecureFlags" -> {
                            // 设置 FLAG_SECURE 防截图
                            window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(true)
                        }
                        "disableSecureFlags" -> {
                            // 清除 FLAG_SECURE
                            window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("EEXCEPTION", e.message, null)
                }
            }

        // MethodChannel: Dart 侧请求系统验证 PIN/密码/图案
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "neko.box/secure_pin")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> {
                        val km = getSystemService(android.content.Context.KEYGUARD_SERVICE)
                            as? android.app.KeyguardManager
                        result.success(km?.isDeviceSecure == true)
                    }
                    "showSystemPin" -> {
                        val title = call.argument<String>("title") ?: "验证身份"
                        val subtitle = call.argument<String>("subtitle") ?: ""
                        val expectedPin = call.argument<String>("expectedPin") ?: ""
                        showSecurePinPrompt(title, subtitle, expectedPin, result)
                    }
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

        // ============================================================
        // 【桌面小组件】MethodChannel + EventChannel（与配置 Activity 共用注册器）
        // ============================================================
        WidgetChannelRegistrar.registerMethodChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        WidgetChannelRegistrar.registerClickEventChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    private fun success(event: Map<String, Any?>?) {
        try {
            shareEventSink?.success(event)
        } catch (_: Exception) { /* sink closed */ }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data
            if (uri?.host == "widget") {
                WidgetClickBus.post(uri.toString())
            } else {
                deepLinkIntent = intent
            }
        }
        // ★ 私密空间 / 每一次分享都走这个分支：解析 + 入队 EventChannel
        val event = ShareReceiverHelper.parse(intent)
        if (event != null) {
            // (1) 推 EventChannel（实时）—— shareEventSink 可能为 null（Dart 未就绪）
            //     这种情况下事件保留在 pendingShareEvent，由 getInitialShare 重试拿取
            pendingShareEvent = event
            try {
                shareEventSink?.success(event)
                pendingShareEvent = null
            } catch (_: Exception) {
                // EventChannel push 失败 → pendingShareEvent 保持已暂存
            }
        }
    }

    override fun onDestroy() {
        shareEventSink = null
        WidgetClickBus.attachSink(null)
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

/**
 * 弹出系统 PIN / 图案 / 密码对话框进行身份验证。
 *
 * 使用 [KeyguardManager.createConfirmDeviceCredentialIntent] 调起系统锁屏验证界面，
 * 用户在系统设置里设置的 PIN / 图案 / 密码都可以通过此界面验证。
 *
 * 通过 startActivityForResult 调起系统 Activity，然后在 onActivityResult 中处理结果。
 *
 * [result].success(true) 表示系统验证通过；success(false) 表示取消或未设置锁屏。
 */
private val SYSTEM_PIN_REQUEST_CODE = 0x5EC0

private fun showSecurePinPrompt(
    title: String,
    subtitle: String,
    @Suppress("UNUSED_PARAMETER") expectedPin: String,
    result: MethodChannel.Result,
) {
    if (securePinResult != null) {
        result.error("EBUSY", "已有正在进行的验证", null)
        return
    }
    securePinResult = result

    val km = getSystemService(android.content.Context.KEYGUARD_SERVICE)
        as? android.app.KeyguardManager
    if (km == null) {
        securePinResult = null
        result.error("ENO_KEYGUARD", "KeyguardManager 不可用", null)
        return
    }

    val intent = km.createConfirmDeviceCredentialIntent(title, subtitle)
    if (intent == null) {
        // 设备没有设置锁屏 PIN/图案/密码
        securePinResult = null
        result.success(false)
        return
    }

    try {
        startActivityForResult(intent, SYSTEM_PIN_REQUEST_CODE)
    } catch (e: Exception) {
        securePinResult = null
        result.error("EEXCEPTION", e.message, null)
    }
}

@Deprecated("Java 会在生成的 Activity 代理中调用（已使用 startActivityForResult）。")
override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    if (requestCode != SYSTEM_PIN_REQUEST_CODE) return
    val pendingResult = securePinResult ?: return
    securePinResult = null
    pendingResult.success(resultCode == Activity.RESULT_OK)
}
}

/**
 * 为用户在桌面创建 Reign（铭记）快捷方式。
 *
 * - 点击快捷方式：打开 MainActivity，带上 memoId + memoType 的 deep link，
 *   Flutter 侧根据路由直接打开对应铭记。
 * - 图标：优先使用传入的 iconBytes；为 null 时使用首字符位图（带彩色背景）。
 *
 * 仅 Android 8.0+（API 26+）支持 requestPinShortcut，本次工程 minSdk 刚好 26。
 *
 * 关键点：使用原生 [ShortcutManager.isRequestPinShortcutSupported] 而非
 * [androidx.core.content.pm.ShortcutManagerCompat.isRequestPinShortcutSupported]，
 * 后者在若干实际支持固定的 Launcher（包括 AOSP/Pixel 桌面及部分国产 ROM）上因元数据不完整，
 * 错误返回 false。这是 Jetpack 兼容库的已知行为偏差。
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

    val shortcutManager = context.getSystemService(ShortcutManager::class.java)
    if (shortcutManager == null || !shortcutManager.isRequestPinShortcutSupported) return false

    // deep link URI → nekobox://memo/{type}/{id}
    val deepLink = Uri.parse("nekobox://memo/$memoType/$memoId")
    val intent = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_VIEW
        data = deepLink
        putExtra("shortcut_memo_id", memoId)
        putExtra("shortcut_memo_type", memoType)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    // 构造图标 (android.graphics.drawable.Icon)
    val icon: Icon = if (iconBytes != null && iconBytes.isNotEmpty()) {
        try {
            val bmp = android.graphics.BitmapFactory.decodeByteArray(iconBytes, 0, iconBytes.size)
            if (bmp != null) Icon.createWithBitmap(bmp) else buildTextIconNative(title, bgColor)
        } catch (_: Exception) {
            buildTextIconNative(title, bgColor)
        }
    } else {
        buildTextIconNative(title, bgColor)
    }

    // 在 ID 后追加时间戳后缀，防止"重复添加同一条铭记"时旧 shortcut 拦截新请求。
    val uniqueId = "memo_shortcut_${memoId}_${System.currentTimeMillis()}"
    val shortLabel = if (title.length <= 8) title else "${title.substring(0, 7)}…"
    return try {
        val builder = ShortcutInfo.Builder(context, uniqueId)
            .setShortLabel(shortLabel)
            .setLongLabel(title)
            .setIcon(icon)
            .setIntents(arrayOf(intent))
        shortcutManager.requestPinShortcut(builder.build(), null)
    } catch (_: Exception) {
        false
    }
}

/**
 * 用铭记标题第一个字符生成带彩色背景的圆形图标位图。
 * 首字符取第一个非空白字符；bgColor 为 null 时使用品牌紫 #6750A4。
 */
private fun buildTextIconNative(title: String, bgColor: Int?): Icon {
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

    return Icon.createWithBitmap(bmp)
}
