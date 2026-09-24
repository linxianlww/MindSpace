package aria.neko.box.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 小组件点击事件的进程内中转。
 *
 * - 冷启动：[MainActivity] 在 onCreate 中把 widget deep link 暂存到 [pendingUri]，
 *   Flutter 开始监听 EventChannel 或调用 getInitialWidgetUri 时取走。
 * - 热启动：onNewIntent 直接经 [post] 推给已就绪的 sink。
 */
object WidgetClickBus {
    @Volatile
    private var pendingUri: String? = null

    @Volatile
    private var sink: EventChannel.EventSink? = null

    @Synchronized
    fun post(uri: String) {
        val current = sink
        if (current != null) {
            try {
                current.success(uri)
            } catch (_: Exception) {
                // sink 已关闭：退化为暂存，等待下一次监听。
                pendingUri = uri
            }
        } else {
            pendingUri = uri
        }
    }

    @Synchronized
    fun consume(): String? {
        val value = pendingUri
        pendingUri = null
        return value
    }

    @Synchronized
    fun attachSink(newSink: EventChannel.EventSink?) {
        sink = newSink
        if (newSink != null) {
            val value = pendingUri
            if (value != null) {
                pendingUri = null
                try {
                    newSink.success(value)
                } catch (_: Exception) {
                    // sink 已关闭：保留待下次。
                    pendingUri = value
                }
            }
        }
    }
}

/**
 * 小组件 MethodChannel / EventChannel 的共享注册器。
 *
 * 关键：主引擎（MainActivity）与配置引擎（各 *ConfigureActivity，各自启动一个
 * 独立 FlutterEngine）都必须注册数据通道。配置页在独立引擎中运行，若该引擎没有
 * "neko.box/widget" 的处理器，Dart 端 saveWidgetData/updateWidget 会收到
 * MissingPluginException（被静默吞掉），导致配置完成后小组件永远没有数据。
 */
object WidgetChannelRegistrar {
    private const val TAG = "WidgetChannel"
    const val METHOD_CHANNEL = "neko.box/widget"
    const val EVENT_CHANNEL = "neko.box/widget/events"
    private const val PREFS_NAME = "HomeWidgetPreferences"

    /**
     * 注册数据通道（Flutter → Native：写数据 / 触发刷新 / 读数据 / 取冷启动 URI）。
     * MainActivity 与各配置 Activity 都应调用。
     */
    fun registerMethodChannel(context: Context, messenger: BinaryMessenger) {
        val appContext = context.applicationContext
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveWidgetData" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key.isNullOrEmpty()) {
                        result.error("EINVAL", "key 为空", null)
                    } else {
                        try {
                            val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            prefs.edit().apply {
                                if (value == null) remove(key) else putString(key, value)
                            }.apply()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("EIO", e.message, null)
                        }
                    }
                }
                "updateWidget" -> {
                    val className = call.argument<String>("className")
                    if (className.isNullOrEmpty()) {
                        result.error("EINVAL", "className 为空", null)
                    } else {
                        try {
                            triggerWidgetUpdate(appContext, className)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.w(TAG, "triggerWidgetUpdate failed: ${e.message}")
                            result.error("ENOENT", e.message, null)
                        }
                    }
                }
                "getWidgetData" -> {
                    val key = call.argument<String>("key")
                    if (key.isNullOrEmpty()) {
                        result.error("EINVAL", "key 为空", null)
                    } else {
                        val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        result.success(prefs.getString(key, null))
                    }
                }
                "getInitialWidgetUri" -> result.success(WidgetClickBus.consume())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 注册点击事件通道（Native → Flutter）。仅 MainActivity 需要；
     * 配置引擎不处理小组件点击。
     */
    fun registerClickEventChannel(context: Context, messenger: BinaryMessenger) {
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    WidgetClickBus.attachSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    WidgetClickBus.attachSink(null)
                }
            }
        )
    }

    /**
     * 触发指定小组件 Provider 的 APPWIDGET_UPDATE 广播。
     * className 可为简单类名（"MemoryListWidgetProvider"）或完整类名。
     */
    private fun triggerWidgetUpdate(context: Context, className: String) {
        val fullClassName = if (className.contains(".")) {
            className
        } else {
            "aria.neko.box.widget.$className"
        }
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, fullClassName)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return

        val clazz = Class.forName(fullClassName)
        val updateIntent = Intent(context, clazz).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(updateIntent)
    }
}
