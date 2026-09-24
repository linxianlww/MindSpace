// 本文件已废弃：原 home_widget 包自带的 @pragma('vm:entry-point') 后台回调。
//
// 现在改为纯原生方案：
// 1) 待办勾选切换：由 TodoToggleReceiver (Kotlin) 直接读写 SharedPreferences 并刷新，
//    无需经过 Flutter isolate。
// 2) 小组件点击路由：由 MainActivity 通过 EventChannel("neko.box/widget/events")
//    推送给 Flutter，在 app.dart 中监听处理。
//
// 保留空文件作为占位标记，避免 import 路径断裂；构建前可物理删除。
