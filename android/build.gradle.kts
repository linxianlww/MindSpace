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
                // 【ABI 策略】ABI 收敛统一由 :app 的 splits.abi(include arm64-v8a) 完成。
                // 但 Flutter Gradle 插件仍会向 :app 注入多 ABI 的 ndk.abiFilters，
                // 而 AGP 规定 ndk.abiFilters 与 splits.abi 互斥（"Conflicting
                // configuration"）。因此在 DSL 最终化阶段（Flutter 注入之后）
                // 清空 ndk.abiFilters，交由 splits 过滤。
                dsl.defaultConfig.ndk.abiFilters.clear()
            }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
