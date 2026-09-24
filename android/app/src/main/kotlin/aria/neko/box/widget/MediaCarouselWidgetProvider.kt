package aria.neko.box.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import aria.neko.box.R

/**
 * 媒体集轮播小组件 (3×2 / 2×2)
 *
 * 采用单 ImageView + AlarmManager 定时轮播下一张图片。
 * AlarmManager 发广播到本 Provider 的 onReceive → advanceIndex → 重绘。
 *
 * 图片以 centerCrop 方式显示在 ImageView 中（scaleType 在 layout 中配置）。
 * 点击打开对应媒体集铭记页面。
 *
 * ANR 防护（关键）：
 *  1. 所有广播经 [WidgetWorker] 在后台线程处理；
 *  2. 图片按小组件实际尺寸 **inSampleSize 采样解码**，绝不全分辨率 decode
 *     （手机照片常达 4000×3000，全分辨率解码 + 经 Binder 传给启动器会让
 *         NekoBox 与启动器双双 ANR / OOM）；
 *  3. 仅在存在 ≥2 张图片时才调度轮播闹钟，间隔 30s（系统对非精确闹钟会进一步合并）。
 */
class MediaCarouselWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_ADVANCE = "aria.neko.box.widget.CAROUSEL_ADVANCE"
        const val ACTION_REFRESH = "aria.neko.box.widget.REFRESH_CAROUSEL"
        private const val INTERVAL_MS = 30_000L
        private const val TAG = "MediaCarousel"
    }

    override fun onReceive(context: Context, intent: Intent) {
        WidgetWorker.runAsync(this, context, intent) {
            super.onReceive(context, intent)
            when (intent.action) {
                ACTION_ADVANCE -> {
                    val images = WidgetDataHelper.getImages(context)
                    if (images.size >= 2) {
                        val cur = WidgetDataHelper.getCurrentIndex(context)
                        WidgetDataHelper.setCurrentIndex(context, (cur + 1) % images.size)
                    }
                    refreshAll(context)
                    reconcileAlarm(context)
                }
                ACTION_REFRESH -> {
                    // Flutter 侧数据变更时重新从 index=0 开始
                    WidgetDataHelper.setCurrentIndex(context, 0)
                    refreshAll(context)
                    reconcileAlarm(context)
                }
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
        reconcileAlarm(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetDataHelper.setCurrentIndex(context, 0)
        // 是否需要闹钟由 onUpdate → reconcileAlarm 根据图片数量决定。
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelAdvance(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    private fun refreshAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(ComponentName(context, MediaCarouselWidgetProvider::class.java))
        for (id in ids) {
            updateAppWidget(context, mgr, id)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.media_carousel_widget)

        val images = WidgetDataHelper.getImages(context)
        val title = WidgetDataHelper.getString(context, "mediaMemoTitle") ?: "媒体集"

        if (images.isEmpty()) {
            views.setImageViewResource(R.id.carousel_image, R.mipmap.ic_launcher)
            views.setTextViewText(R.id.carousel_caption, "$title · 暂无图片")
        } else {
            val idx = WidgetDataHelper.getCurrentIndex(context).let {
                if (images.size == 1) 0 else it % images.size
            }
            val targetPx = targetEdgePx(context, appWidgetManager, appWidgetId)
            val bmp = decodeSampledBitmap(images[idx].path, targetPx)
            if (bmp != null) {
                views.setImageViewBitmap(R.id.carousel_image, bmp)
            } else {
                Log.d(TAG, "decode failed: ${images[idx].path}")
                views.setImageViewResource(R.id.carousel_image, R.mipmap.ic_launcher)
            }
            views.setTextViewText(R.id.carousel_caption, "📷 $title (${idx + 1}/${images.size})")
        }

        // 点击 → 打开媒体集铭记
        val memoId = WidgetDataHelper.getString(context, "mediaMemoId") ?: ""
        val openUri = if (memoId.isNotEmpty()) "nekobox://memo/media/$memoId" else "nekobox://widget/openMediaList"
        val openIntent = Intent(context, aria.neko.box.MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(openUri)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            context, 200, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.carousel_container, openPending)
        views.setOnClickPendingIntent(R.id.carousel_image, openPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 根据当前图片数量决定是否需要轮播闹钟：≥2 张才调度，否则取消，
     * 避免空数据时每 10s 唤醒一次设备。
     */
    private fun reconcileAlarm(context: Context) {
        val images = WidgetDataHelper.getImages(context)
        if (images.size >= 2) {
            scheduleAdvance(context)
        } else {
            cancelAdvance(context)
        }
    }

    /**
     * 计算解码目标边长（px）：取小组件当前最大宽度 dp × 密度 × 2（保证清晰度），
     * 限制在 240~1080px。取不到尺寸信息时回退 720px。
     */
    private fun targetEdgePx(context: Context, mgr: AppWidgetManager, appWidgetId: Int): Int {
        return try {
            val options = mgr.getAppWidgetOptions(appWidgetId)
            val maxWidthDp = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0) ?: 0
            val density = context.resources.displayMetrics.density.coerceAtLeast(1f)
            val px = (maxWidthDp * density * 2f).toInt()
            px.coerceIn(240, 1080)
        } catch (_: Exception) {
            720
        }
    }

    /**
     * 先查尺寸再按 inSampleSize 采样解码，把内存占用控制在小组件所需量级
     * （目标边最长约 1080px，ARGB_8888 约 3~4MB，远小于原图的数十 MB）。
     */
    private fun decodeSampledBitmap(path: String, targetEdgePx: Int): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

            var sample = 1
            val largest = maxOf(bounds.outWidth, bounds.outHeight)
            while (largest / (sample * 2) >= targetEdgePx) {
                sample *= 2
            }
            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeFile(path, opts)
        } catch (e: Exception) {
            Log.d(TAG, "decode sampled failed: ${e.message}")
            null
        }
    }

    private fun scheduleAdvance(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, MediaCarouselWidgetProvider::class.java).apply {
            action = ACTION_ADVANCE
        }
        val pending = PendingIntent.getBroadcast(
            context, 300, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarm.cancel(pending)
        // 非精确重复闹钟，不需要 SCHEDULE_EXACT_ALARM 权限；系统会按最小间隔合并。
        alarm.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + INTERVAL_MS,
            INTERVAL_MS,
            pending
        )
    }

    private fun cancelAdvance(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(context, MediaCarouselWidgetProvider::class.java).apply {
            action = ACTION_ADVANCE
        }
        val pending = PendingIntent.getBroadcast(
            context, 300, intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pending != null) {
            alarm.cancel(pending)
            pending.cancel()
        }
    }
}
