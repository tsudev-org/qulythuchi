import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tsudev.qulythuchi"
    // flutter_local_notifications 23 + androidx.core 1.19 đòi biên dịch với API 37 (checkReleaseAarMetadata). Chỉ đổi
    // compileSdk; targetSdk vẫn theo Flutter nên hành vi lúc chạy không đổi.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications cần desugaring (java.time trên Android cũ).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tsudev.qulythuchi"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Khóa ký phát hành: workflow Release ghi `android/key.properties` từ secret Environment `release` rồi xoá ngay sau
    // khi dựng (DISTRIBUTION_TRUST.md mục 1.3, 2.4). Máy dev không có tệp này ⇒ `flutter run --release` dùng khóa debug;
    // CI đặt QLTC_REQUIRE_RELEASE_KEY=1 để KHÔNG BAO GIỜ phát hành tệp ký bằng khóa debug.
    val keyFile = rootProject.file("key.properties")
    if (keyFile.exists()) {
        val props = Properties().apply { keyFile.inputStream().use { load(it) } }
        signingConfigs {
            create("release") {
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    } else if (System.getenv("QLTC_REQUIRE_RELEASE_KEY") == "1") {
        throw GradleException("Thiếu android/key.properties - không phát hành tệp ký bằng khóa debug.")
    }

    buildTypes {
        release {
            signingConfig =
                if (keyFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    // Theme.AppCompat cho hộp thoại sinh trắc của local_auth (tránh lỗi trên Android 8 trở xuống).
    implementation("androidx.appcompat:appcompat:1.7.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
