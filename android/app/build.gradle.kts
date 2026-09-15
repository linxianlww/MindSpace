plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "aria.neko.box"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "aria.neko.box"
        // 【兼容性】minSdk = 26（Android 8.0）：
        // ① 产品要求支持 Android 8.x；
        // ② java.time 自 API 26 起为系统原生 API，避免依赖任何需 desugar 的路径；
        // ③ 所有插件 minSdk 均 ≤21，上提无冲突。
        // 注意：不使用 flutter.minSdkVersion（24），显式固定。
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 【硬约束】仅打包 arm64-v8a。
    // 不在此声明 ndk.abiFilters / splits：Flutter Gradle 插件会在配置期向 :app 注入
    // 完整 ABI 集合（armeabi-v7a,arm64-v8a,x86_64），此处手写会被覆盖或与之冲突。
    // 真正的单一 ABI 过滤在根 build.gradle.kts 的 androidComponents.finalizeDsl 中完成
    // （在 Flutter 注入之后清空并只保留 arm64-v8a），构建后解压 APK 核验只含 lib/arm64-v8a。

    buildTypes {
        release {
            // 先用 debug 签名，便于直接 flutter run --release；正式发布再替换自有签名。
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
