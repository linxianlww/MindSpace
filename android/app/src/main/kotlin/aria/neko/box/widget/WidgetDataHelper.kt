package aria.neko.box.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * 小组件数据助手指向 SharedPreferences("HomeWidgetPreferences")。
 * 所有小组件 Provider / Service / Receiver 统一从这里读取与写入，
 * 数据格式与 Flutter 侧 home_widget_service.dart 的输出严格对齐。
 */
object WidgetDataHelper {

    private const val PREFS_NAME = "HomeWidgetPreferences"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // ──────────────────────────────────────────────
    // 通用
    // ──────────────────────────────────────────────

    fun getString(context: Context, key: String, default: String? = null): String? =
        prefs(context).getString(key, default)

    fun putString(context: Context, key: String, value: String?) {
        prefs(context).edit().apply {
            if (value == null) remove(key) else putString(key, value)
        }.apply()
    }

    // ──────────────────────────────────────────────
    // 铭记列表组 (MemoryList)
    // key: memosJson / folderId / folderName
    // memosJson 结构: [{id,type,title,subtitle,color,thumbPath}]
    // ──────────────────────────────────────────────

    data class MemoEntry(
        val id: String,
        val type: String,
        val title: String,
        val subtitle: String,
        val color: Int,
        val thumbPath: String?
    )

    fun getMemos(context: Context): List<MemoEntry> {
        val raw = getString(context, "memosJson") ?: return emptyList()
        if (raw.isBlank()) return emptyList()
        return parseMemos(raw)
    }

    private fun parseMemos(raw: String): List<MemoEntry> {
        val result = mutableListOf<MemoEntry>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                result.add(
                    MemoEntry(
                        id = o.optString("id"),
                        type = o.optString("type"),
                        title = o.optString("title"),
                        subtitle = o.optString("subtitle"),
                        color = o.optInt("color", 0),
                        thumbPath = o.optString("thumbPath").ifEmpty { null }
                    )
                )
            }
        } catch (_: Exception) { }
        return result
    }

    // ──────────────────────────────────────────────
    // 待办事项组 (TodoList)
    // key: todoMemoId / todoTitle / todoJson / todoFilePath
    // todoJson 结构: [{id,text,checked,sortOrder}]
    // ──────────────────────────────────────────────

    data class TodoEntry(
        val id: String,
        val text: String,
        val checked: Boolean,
        val sortOrder: Int
    )

    fun getTodos(context: Context): List<TodoEntry> {
        val raw = getString(context, "todoJson") ?: return emptyList()
        if (raw.isBlank()) return emptyList()
        return parseTodos(raw)
    }

    private fun parseTodos(raw: String): List<TodoEntry> {
        val result = mutableListOf<TodoEntry>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                result.add(
                    TodoEntry(
                        id = o.optString("id"),
                        text = o.optString("text"),
                        checked = o.optBoolean("checked", false),
                        sortOrder = o.optInt("sortOrder", 0)
                    )
                )
            }
        } catch (_: Exception) { }
        return result.sortedBy { it.sortOrder }
    }

    /**
     * 持久化 todo 列表到 SharedPreferences。
     * 同时把相同数据写入 todoFilePath 指向的磁盘文件（与主应用内存中的 content.todo.json 保持同步）。
     */
    fun saveTodos(context: Context, entries: List<TodoEntry>) {
        val arr = JSONArray()
        entries.forEach { e ->
            arr.put(JSONObject().apply {
                put("id", e.id)
                put("text", e.text)
                put("checked", e.checked)
                put("sortOrder", e.sortOrder)
            })
        }
        val json = arr.toString()
        putString(context, "todoJson", json)

        // 同步写磁盘文件（todoFilePath），确保主应用下次启动时能读到最新状态
        val filePath = getString(context, "todoFilePath")
        if (!filePath.isNullOrEmpty()) {
            try {
                val file = java.io.File(filePath)
                file.parentFile?.mkdirs()
                file.writeText(json)
            } catch (_: Exception) { }
        }
    }

    // ──────────────────────────────────────────────
    // 媒体轮播组 (MediaCarousel)
    // key: imagePaths (逗号分隔的绝对路径) / mediaMemoId / currentImageIndex
    // ──────────────────────────────────────────────

    data class ImageEntry(val path: String)

    fun getImages(context: Context): List<ImageEntry> {
        val raw = getString(context, "imagePaths") ?: return emptyList()
        if (raw.isBlank()) return emptyList()
        return raw.split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .map { ImageEntry(it) }
    }

    fun getCurrentIndex(context: Context): Int =
        prefs(context).getInt("currentImageIndex", 0)

    fun setCurrentIndex(context: Context, index: Int) {
        prefs(context).edit().putInt("currentImageIndex", index).apply()
    }

    // ──────────────────────────────────────────────
    // 工具
    // ──────────────────────────────────────────────

    /** 刷新指定 provider 的所有实例。 */
    fun refreshWidget(context: Context, providerClass: Class<*>) {
        val manager = AppWidgetManager.getInstance(context)
        val component = android.content.ComponentName(context, providerClass.name)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return
        val intent = Intent(context, providerClass).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(intent)
    }
}
