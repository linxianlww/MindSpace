package aria.neko.box.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import aria.neko.box.R

/**
 * 待办事项列表小组件 (4×3 / 5×3)
 *
 * 采用 ScrollView + LinearLayout + addView 静态渲染方案。
 * 每一项的 CheckBox 点击触发 TodoToggleReceiver，完成状态写入 SharedPreferences + 磁盘原文件。
 *
 * 性能：所有广播都通过 [WidgetWorker] 在后台线程处理，避免主线程 I/O 与 ANR。
 */
class TodoListWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE = "aria.neko.box.widget.TOGGLE_TODO_V2"
        const val EXTRA_ITEM_ID = "extra_item_id"
        const val ACTION_REFRESH = "aria.neko.box.widget.REFRESH_TODO_LIST"
    }

    override fun onReceive(context: Context, intent: Intent) {
        WidgetWorker.runAsync(this, context, intent) {
            super.onReceive(context, intent)
            if (intent.action == ACTION_REFRESH) {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(
                    ComponentName(context, TodoListWidgetProvider::class.java)
                )
                for (id in ids) updateAppWidget(context, mgr, id)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.todo_list_widget)

        // 标题
        val title = WidgetDataHelper.getString(context, "todoTitle") ?: "待办事项"
        views.setTextViewText(R.id.todo_title, "☑ $title")

        // 待办项
        val todos = WidgetDataHelper.getTodos(context)
        views.removeAllViews(R.id.todo_container)

        for (todo in todos.take(30)) {
            val item = RemoteViews(context.packageName, R.layout.todo_list_item)
            val displayText = "${if (todo.checked) "☑" else "☐"} ${todo.text}"
            item.setTextViewText(R.id.todo_text, displayText)
            val textColor = if (todo.checked) 0xFF9E9E9E.toInt() else 0xFF1C1B1F.toInt()
            item.setTextColor(R.id.todo_text, textColor)

            // 点击 CheckBox/行 → toggle
            val toggleIntent = Intent(context, TodoToggleReceiver::class.java).apply {
                action = ACTION_TOGGLE
                putExtra(EXTRA_ITEM_ID, todo.id)
            }
            val pending = PendingIntent.getBroadcast(
                context,
                todo.id.hashCode() + 1000,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            item.setOnClickPendingIntent(R.id.todo_checkbox, pending)
            item.setOnClickPendingIntent(R.id.todo_item_container, pending)

            views.addView(R.id.todo_container, item)
        }

        // 空态：无数据时显示“暂无数据”，有数据时隐藏
        views.setViewVisibility(
            R.id.todo_empty,
            if (todos.isEmpty()) android.view.View.VISIBLE else android.view.View.GONE
        )

        // 标题点击 → 打开 app
        val openIntent = Intent(context, aria.neko.box.MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("nekobox://widget/openTodoList")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            context, 101, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.todo_title, openPending)
        views.setOnClickPendingIntent(R.id.todo_header, openPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
