plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aria.mindspace"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.aria.mindspace"
        // 录音(record)、PDF(pdfrx) 等插件要求最低 API 23，统一提升到 23。
        minSdk = flutter.minSdkVersion
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
