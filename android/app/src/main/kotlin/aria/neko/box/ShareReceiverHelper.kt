package aria.neko.box

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream

/**
 * 统一处理通过 Intent 进入的分享/TOTP/文本选择数据。
 *
 * PROCESS_TEXT     -> 文本铭记（从 EXTRA_PROCESS_TEXT 读文本）
 * SEND (单文件)    -> 按 MIME 类型分流（文本/图片/视频/音频/通用文件）
 * SEND_MULTIPLE    -> 媒体集（多张图片 / 多个视频一次性导入）
 * VIEW (otpauth://)-> TOTP 铭记
 *
 * 所有文件通过 MethodChannel 把 URI/路径 传给 Dart 侧做最终落盘 + 入库。
 */
object ShareReceiverHelper {

    // 把收到的 intent 序列化为 Dart 可消费的 Map；解析失败返回 null。
    fun parse(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val action = when (intent.action) {
            Intent.ACTION_PROCESS_TEXT -> parseProcessText(intent)
            Intent.ACTION_SEND -> parseSend(intent)
            Intent.ACTION_SEND_MULTIPLE -> parseSendMultiple(intent)
            Intent.ACTION_VIEW -> parseView(intent)
            else -> null
        } ?: return null
        // 如果 Intent 携带 targetFolderId（从 ShareReceiverActivity 转发过来为私密空间标记），
        // 注入到返回的 map 中，以便 Dart 侧按字段分流。
        val targetFolderId = intent.getStringExtra(ShareReceiverActivity.EXTRA_TARGET_FOLDER_ID)
        return if (targetFolderId != null) {
            action + ("targetFolderId" to targetFolderId)
        } else {
            action
        }
    }

    // —— 文本选择菜单（PROCESS_TEXT）——
    private fun parseProcessText(intent: Intent): Map<String, Any?>? {
        // 只读选中文本（编辑不可读时使用 EXTRA_PROCESS_TEXT_READONLY）
        // 但我们的场景是「导入为铭记」，相当于「吃掉」原文，直接读即可。
        val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            ?: return null
        if (text.isBlank()) return null
        // 可选：附带的只读标记（我们忽略，因为导入后原文不受影响）
        val readOnly = intent.getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)
        return mapOf(
            "action" to "process_text",
            "text" to text,
            "readOnly" to readOnly,
            // 文本选择：没有文件名，用前 40 字符作为标题候选
            "title" to text.take(40)
        )
    }

    // —— SEND 单文件 / 单段文本 ——
    private fun parseSend(intent: Intent): Map<String, Any?>? {
        val mime = intent.type ?: ""
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        val subject = intent.getCharSequenceExtra(Intent.EXTRA_SUBJECT)?.toString()
        val stream = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)

        // 纯文本分享（无文件 URI）
        if (stream == null && !text.isNullOrBlank()) {
            return mapOf(
                "action" to "send_text",
                "mime" to mime,
                "text" to text,
                "subject" to (subject ?: ""),
                "title" to ((subject ?: text.take(40)))
            )
        }

        // 文件 URI 分享
        if (stream != null) {
            // 授权持久化——让 Dart 侧可以在任意时刻读取这些 URI
            val flags = intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
            return mapOf(
                "action" to "send_file",
                "mime" to mime,
                "uri" to stream.toString(),
                "displayName" to queryDisplayName(stream),
                "text" to (text ?: ""),
                "subject" to (subject ?: "")
            )
        }

        return null
    }

    // —— SEND_MULTIPLE（复数文件，通常为多图/多视频）——
    private fun parseSendMultiple(intent: Intent): Map<String, Any?>? {
        val mime = intent.type ?: ""
        val items: ArrayList<Uri> = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM) ?: arrayListOf()
        if (items.isEmpty()) return null
        val list = items.map { uri ->
            mapOf(
                "uri" to uri.toString(),
                "mime" to mime,
                "displayName" to queryDisplayName(uri)
            )
        }
        return mapOf(
            "action" to "send_multiple",
            "mime" to mime,
            "items" to list,
            "count" to list.size
        )
    }

    // —— VIEW otpauth:// TOTP ——
    private fun parseView(intent: Intent): Map<String, Any?>? {
        val data = intent.data ?: return null
        if (data.scheme?.lowercase() != "otpauth") return null
        return mapOf(
            "action" to "view_totp",
            "uri" to data.toString()
        )
    }

    // —— ContentResolver 读取显示名 ——
    private fun queryDisplayName(uri: Uri): String? {
        return try {
            uri.host?.let { }  // 触发一次检查，避免 NPE
            val resolver = AppContextResolver.resolver ?: return lastPathSegment(uri)
            resolver.query(uri, null, null, null, null)?.use { c ->
                val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0 && c.moveToFirst()) c.getString(idx) else lastPathSegment(uri)
            } ?: lastPathSegment(uri)
        } catch (_: Exception) {
            lastPathSegment(uri)
        }
    }

    private fun lastPathSegment(uri: Uri): String? {
        val seg = uri.lastPathSegment ?: return null
        val slash = seg.lastIndexOf('/')
        return if (slash >= 0) seg.substring(slash + 1) else seg
    }

    // 读 URI 到字节数组（用于无法直接传递路径的场景）。
    fun uriToBytes(uri: Uri): ByteArray? {
        return try {
            val resolver = AppContextResolver.resolver ?: return null
            resolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (_: Exception) { null }
    }

    // 把 URI 持久化到应用缓存目录（share_import 子目录），返回文件绝对路径。
    // 用于 SEND 类分享，Flutter 侧收到路径后执行标准导入流程。
    fun persistUri(uri: Uri, suggestedName: String?): String? {
        return try {
            val resolver = AppContextResolver.resolver ?: return null
            val name = suggestedName ?: queryDisplayName(uri) ?: "shared_${System.currentTimeMillis()}"
            val cacheDir = File(AppContextResolver.cacheDir, "share_import").apply { mkdirs() }
            val file = File(cacheDir, name)
            resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
            file.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    // 批量 persist 多文件（SEND_MULTIPLE）。返回路径列表。
    fun persistUris(items: List<Map<String, Any?>>): List<String> {
        val result = mutableListOf<String>()
        for (item in items) {
            val uriStr = item["uri"] as? String ?: continue
            val uri = Uri.parse(uriStr)
            val name = item["displayName"] as? String
            val path = persistUri(uri, name) ?: continue
            result.add(path)
        }
        return result
    }
}

/**
 * 全局持有 ContentResolver 和 cacheDir，由 MainActivity 初始化时注入。
 */
object AppContextResolver {
    var resolver: android.content.ContentResolver? = null
    var cacheDir: File? = null
}
