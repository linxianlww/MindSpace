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
 * 铭记列表小组件 (4×3 / 5×3)
 *
 * 采用 ScrollView + LinearLayout + addView 静态渲染方案。
 * 在 onUpdate 中为每一项创建一个 item RemoteViews，再通过 parent.addView(id, item) 添加。
 * 每项 item 自带 setOnClickPendingIntent，点击打开对应铭记。
 *
 * 性能：所有广播（含 onUpdate / 自定义刷新）都通过 [WidgetWorker] 在后台线程处理，
 * 避免在主线程读 SharedPreferences、解析 JSON 与构建大量 RemoteViews 触发 ANR。
 */
class MemoryListWidgetProvider : AppWidgetProvider() {

    companion object {
        const val EXTRA_MEMO_URI = "extra_memo_uri"
        /** Flutter 侧 MethodChannel 调用 updateWidget 时触发此 action 强制重绘 */
        const val ACTION_REFRESH = "aria.neko.box.widget.REFRESH_MEMORY_LIST"
    }

    override fun onReceive(context: Context, intent: Intent) {
        // goAsync + 后台线程：super.onReceive 会在该后台线程分发 onUpdate 等回调。
        WidgetWorker.runAsync(this, context, intent) {
            super.onReceive(context, intent)
            if (intent.action == ACTION_REFRESH) {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(
                    ComponentName(context, MemoryListWidgetProvider::class.java)
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
        val views = RemoteViews(context.packageName, R.layout.memory_list_widget)

        // 标题 + 文件夹名
        val folderName = WidgetDataHelper.getString(context, "folderName") ?: "根目录"
        val memos = WidgetDataHelper.getMemos(context)
        views.setTextViewText(R.id.memory_title, "📂 $folderName")
        views.setTextViewText(R.id.memory_count, "(${memos.size})")

        // 清空容器，逐项 addView
        views.removeAllViews(R.id.memory_container)
        for (memo in memos.take(30)) {
            val item = RemoteViews(context.packageName, R.layout.memory_list_item)
            item.setTextViewText(R.id.item_title, memo.title.ifEmpty { "无标题" })
            item.setTextViewText(R.id.item_subtitle, memo.subtitle)
            // 颜色条
            val color = if (memo.color != 0) memo.color else 0xFFFF6D00.toInt()
            item.setInt(R.id.item_color_bar, "setBackgroundColor", color)
            // 类型图标
            item.setTextViewText(R.id.item_icon, typeIcon(memo.type))
            item.setViewVisibility(R.id.item_thumb, android.view.View.GONE)
            item.setViewVisibility(R.id.item_icon, android.view.View.VISIBLE)

            // 点击 intent
            val clickIntent = Intent(context, aria.neko.box.MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("nekobox://memo/${memo.type}/${memo.id}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                memo.id.hashCode(),
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            item.setOnClickPendingIntent(R.id.item_container, pending)

            views.addView(R.id.memory_container, item)
        }

        // 空态：无数据时显示“暂无数据”，有数据时隐藏（它在 FrameLayout 中会盖住列表）
        views.setViewVisibility(
            R.id.memory_empty,
            if (memos.isEmpty()) android.view.View.VISIBLE else android.view.View.GONE
        )

        // 标题点击 → 打开 app
        val openIntent = Intent(context, aria.neko.box.MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("nekobox://widget/openMemoList")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            context, 100, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.memory_title, openPending)
        views.setOnClickPendingIntent(R.id.memory_header, openPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun typeIcon(type: String): String = when (type) {
        "text"  -> "📝"
        "media" -> "📷"
        "audio" -> "🎵"
        "file"  -> "📄"
        "todo"  -> "☑"
        "totp"  -> "🔑"
        "anniversary" -> "📅"
        else    -> "📌"
    }
}
