package aria.neko.box.widget

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 小组件配置专用 Activity：以 Flutter 页面让用户选择文件夹/铭记。
 *
 * 在小组件配置流程中运行 configureMain 入口
 * （见 lib/features/home/widgets/widget_configure_main.dart），
 * 读取 FlutterSharedPreferences 中的 appWidgetId（本 Activity 写入），显示配置 UI。
 *
 * 配置完成后，Dart 端通过 MethodChannel("neko.box/widget_config") 调用 finishWithSuccess，
 * Activity 设置 RESULT_OK 并 finish，系统便可完成小组件添加。
 *
 * 注意：本 Activity 启动的是**独立 Flutter 引擎**，因此除了 widget_config 通道外，
 * 还必须注册 neko.box/widget 数据通道（见 [WidgetChannelRegistrar]），
 * 否则配置页写入的小组件数据会因 MissingPluginException 而静默丢失。
 */

abstract class BaseWidgetConfigureActivity : FlutterActivity() {

    protected var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        // 关键修复顺序：读取 widget ID + 写入 SharedPreferences 必须在 super.onCreate 之前完成，
        // 因为 super.onCreate 会启动 Flutter 引擎并执行 configureMain 入口；
        // 若此时 SharedPreferences 还未写入，Dart 侧读到空的 appWidgetId，UI 卡死在 loading。
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            // 没有合法 widget id（异常拉起/系统恢复场景）：直接取消并关闭，
            // 绝不能启动 Flutter 引擎后停在空白页——那会让启动器的“添加小组件”
            // 流程永久等待 Activity Result，表现为启动器与应用双双卡死/ANR。
            setResult(RESULT_CANCELED)
            finish()
            return
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        // apply() 即可：同进程内内存映射立即可见，Dart 侧通过平台通道读取发生在
        // 引擎启动（数百毫秒后），磁盘落盘由系统异步完成；主线程 commit() 同步写盘
        // 在低配机上会无谓地拖慢冷启动、加剧 ANR 风险。
        prefs.edit()
            .putInt("flutter.appWidgetId", appWidgetId)
            .putString("flutter.widgetClassName", this::class.java.name)
            .apply()

        super.onCreate(savedInstanceState)

        // 用户取消（返回键）时的默认返回值
        setResult(RESULT_CANCELED)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 数据通道：配置页保存小组件数据 / 触发刷新（与 MainActivity 同一套实现）
        WidgetChannelRegistrar.registerMethodChannel(this, flutterEngine.dartExecutor.binaryMessenger)

        // 注册 MethodChannel：Dart 端配置完成后调用 finishWithSuccess
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "neko.box/widget_config")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "finishWithSuccess" -> {
                        finishWithSuccess()
                        result.success(true)
                    }
                    "cancel" -> {
                        finishWithCancel()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    protected fun finishWithSuccess() {
        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultValue)
        finish()
    }

    private fun finishWithCancel() {
        setResult(RESULT_CANCELED)
        finish()
    }
}

class MemoryListWidgetConfigureActivity : BaseWidgetConfigureActivity() {
    override fun getDartEntrypointFunctionName(): String = "configureMain"
}

class TodoListWidgetConfigureActivity : BaseWidgetConfigureActivity() {
    override fun getDartEntrypointFunctionName(): String = "configureMain"
}

class MediaCarouselWidgetConfigureActivity : BaseWidgetConfigureActivity() {
    override fun getDartEntrypointFunctionName(): String = "configureMain"
}
