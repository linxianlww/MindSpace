package aria.neko.box.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import aria.neko.box.R

/**
 * 快捷操作小组件 (2×1)
 *
 * 布局：两个等大圆角按钮并排
 *  - 左：新建文本铭记 → nekobox://widget/newText
 *  - 右：添加待办     → nekobox://widget/addTodo
 *
 * 数据：静态，不需要从 SharedPreferences 读取。
 */
class QuickActionsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
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
        val views = RemoteViews(context.packageName, R.layout.quick_actions_widget)

        // 左按钮：新建文本铭记 → app.dart 路由 widget/create/text
        val newTextIntent = Intent(context, aria.neko.box.MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("nekobox://widget/create/text")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val newTextPending = PendingIntent.getActivity(
            context, 0, newTextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_new_text, newTextPending)

        // 右按钮：添加待办 → app.dart 路由 widget/create/todo
        val addTodoIntent = Intent(context, aria.neko.box.MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("nekobox://widget/create/todo")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addTodoPending = PendingIntent.getActivity(
            context, 1, addTodoIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_add_todo, addTodoPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
