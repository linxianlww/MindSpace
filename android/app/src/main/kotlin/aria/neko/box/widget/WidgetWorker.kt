package aria.neko.box.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * 小组件广播的后台执行器。
 *
 * AppWidgetProvider / BroadcastReceiver 的 onReceive 运行在**主线程**，
 * 系统给广播接收器的 ANR 预算约 10s（部分国产 ROM 更短）。小组件刷新涉及
 * SharedPreferences 读写、JSON 解析、数十个 RemoteViews 构建、图片解码与磁盘
 * 文件同步写入——这些都不能在主线程做，否则：
 *   1. NekoBox 自身触发 Broadcast ANR；
 *   2. 启动器（AppWidgetHost）在主线程 apply RemoteViews（含大图）时也会 ANR。
 *
 * 统一用 [goAsync] 拿到 PendingResult，把工作丢到单线程后台 executor，
 * 完成后再 finish()。
 */
object WidgetWorker {
    private const val TAG = "WidgetWorker"

    // 单线程即可：微件刷新是低频任务，串行还能避免并发读写同一份 SharedPreferences。
    private val executor: ExecutorService =
        Executors.newSingleThreadExecutor { r ->
            Thread(r, "neko-widget-worker").apply { isDaemon = true }
        }

    /**
     * 在后台线程执行 [block]，并在结束后完成广播。
     * 任何异常都被吞掉并记录，避免 PendingResult 泄漏导致系统 ANR。
     */
    fun runAsync(receiver: BroadcastReceiver, context: Context, intent: Intent, block: () -> Unit) {
        val pending = receiver.goAsync()
        executor.execute {
            try {
                block()
            } catch (t: Throwable) {
                Log.w(TAG, "widget broadcast ${intent.action} failed: ${t.message}", t)
            } finally {
                try {
                    pending.finish()
                } catch (_: Exception) {
                    // 已 finish 等极端情况，忽略。
                }
            }
        }
    }
}
