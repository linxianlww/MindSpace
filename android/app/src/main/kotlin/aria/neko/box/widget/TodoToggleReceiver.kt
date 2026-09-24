package aria.neko.box.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 待办勾选切换广播接收器
 *
 * 接收小组件 ListView 中 CheckBox 的 fillInIntent 回调。
 * 根据 itemId 在 todoJson 中找到对应项，切换 checked 状态，
 * 更新 SharedPreferences 与磁盘原文件（todoFilePath），然后刷新 widget。
 *
 * 纯原生实现，不需要经过 Flutter 主 isolate。
 *
 * 性能：SharedPreferences 写入 + 磁盘文件 writeText 都在后台线程执行
 * （[WidgetWorker.runAsync] + goAsync），避免在主线程做磁盘 I/O 触发 ANR。
 */
class TodoToggleReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "TodoToggleReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TodoListWidgetProvider.ACTION_TOGGLE) return

        WidgetWorker.runAsync(this, context, intent) {
            val itemId = intent.getStringExtra(TodoListWidgetProvider.EXTRA_ITEM_ID)
                ?: return@runAsync
            Log.d(TAG, "toggle item=$itemId")

            val entries = WidgetDataHelper.getTodos(context).toMutableList()
            val idx = entries.indexOfFirst { it.id == itemId }
            if (idx < 0) return@runAsync

            // 切换状态
            entries[idx] = entries[idx].copy(checked = !entries[idx].checked)

            // 持久化（SharedPreferences + 磁盘原文件，均在后台线程）
            WidgetDataHelper.saveTodos(context, entries)

            // 发送自定义广播触发 provider 重绘（provider 同样在后台线程处理）
            val refreshIntent = Intent(context, TodoListWidgetProvider::class.java).apply {
                action = TodoListWidgetProvider.ACTION_REFRESH
            }
            context.sendBroadcast(refreshIntent)
        }
    }
}
