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

    // 【ABI 策略】默认 release 仅 arm64-v8a，输出单个 APK 且仅含 lib/arm64-v8a。
    // 使用 splits.abi 而非 ndk.abiFilters：
    // ① AGP 规定两者互斥，设置前者时后者必须为空；
    // ② Flutter 的 --split-per-abi 会在同一块上设置 include+resetToUniversalApk=false，
    //    覆盖本配置为三分 APK（arm64-v8a/armeabi-v7a/x86_64），天然兼容；
    // ③ 普通 release（无 --split-per-abi）命中本配置，resetToUniversalApk=false 确保
    //    不生成 universal APK，include=[arm64-v8a] 使合并原生库与打包都仅针对该 ABI。
    splits {
        abi {
            isEnable = true
            isUniversalApk = false
            include("arm64-v8a")
        }
    }

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

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
}
