package aria.neko.box

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * 透明中场 Activity：在系统分享表中以「保存到私密空间」身份出现。
 *
 * 用户点选该入口后系统把 ACTION_SEND / SEND_MULTIPLE 派发给本 Activity；
 * 本 Activity 立刻把 target = __private_space__ 标记写入 Intent extra，
 * 然后启动 MainActivity（singleTop 复用现有实例），由 MainActivity
 * 在解析分享时读取 extra 并写入 pendingShareEvent，供 Dart getInitialShare 消费。
 */
class ShareReceiverActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 把 targetFolderId 标记写入 intent extra，转发给主 Activity
        val forward = Intent(this, MainActivity::class.java).apply {
            action = intent.action
            type = intent.type
            // 复制所有数据（EXTRA_TEXT / EXTRA_STREAM 等）
            if (intent.extras != null) putExtras(intent.extras!!)
            // 标记目标文件夹为私密空间
            putExtra(EXTRA_TARGET_FOLDER_ID, PRIVATE_SPACE_FOLDER_ID)
            // singleTop 复用已有实例 → onNewIntent 被调用
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(forward)
        finish()
    }

    companion object {
        const val EXTRA_TARGET_FOLDER_ID = "aria.neko.box.TARGET_FOLDER_ID"
        const val PRIVATE_SPACE_FOLDER_ID = "__private_space__"
    }
}
