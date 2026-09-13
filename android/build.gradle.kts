allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 【MindSpace 构建兼容性】大量第三方插件（file_picker/just_audio/share_plus/
// audio_waveforms/package_info_plus/permission_handler_android/wakelock_plus 等）
// 在自身 build.gradle 中硬编码 compileSdk 34/35，而最新的
// flutter_plugin_android_lifecycle 等要求 compileSdk 36，否则 checkReleaseAarMetadata
// 失败。AGP 9 已禁止在 afterEvaluate 改 compileSdk（会抛 "moving this call to be
// during evaluation"），因此这里使用官方变体 API 的 finalizeDsl：它在模块自身
// android{} 配置完成之后、变体创建与 DSL 锁定之前回调，是 AGP 8/9 均合法的覆盖时机。
subprojects {
    plugins.withId("com.android.library") {
        extensions
            .findByType(com.android.build.api.variant.LibraryAndroidComponentsExtension::class.java)
            ?.finalizeDsl { it.compileSdk = 36 }
    }
    plugins.withId("com.android.application") {
        extensions
            .findByType(com.android.build.api.variant.ApplicationAndroidComponentsExtension::class.java)
            ?.finalizeDsl { dsl ->
                dsl.compileSdk = 36
                // 【硬约束·仅 arm64-v8a】Flutter Gradle 插件会在配置期向 :app 注入完整
                // ABI 集合（armeabi-v7a,arm64-v8a,x86_64），导致 Dart 原生资产
                // (libdartjni/libdatastore_shared_counter) 等按全部 ABI 打包。这里在
                // DSL 最终化阶段（Flutter 注入之后、变体锁定之前）清空并只保留 arm64-v8a，
                // mergeNativeLibs 会据此过滤所有来源的原生库，最终 APK 仅含 lib/arm64-v8a。
                dsl.defaultConfig.ndk.abiFilters.clear()
                dsl.defaultConfig.ndk.abiFilters.add("arm64-v8a")
            }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
