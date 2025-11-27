plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    //    id "com.chaquo.python"
}
//apply plugin: 'com.chaquo.python'
android {
    namespace = "com.tapuniverse.passportphoto"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tapuniverse.passportphoto"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        externalNativeBuild {
            // For ndk-build, instead use the ndkBuild block.
            cmake {
                // Passes optional arguments to CMake.
                arguments += listOf("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(project(":popup-feedback"))
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.heifwriter:heifwriter:1.0.0")

    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.mlkit:object-detection-common:18.0.0")
    implementation("com.google.ai.edge.litert:litert-support-api:1.4.0")


    // TensorFlow Lite core
//    implementation 'org.tensorflow:tensorflow-lite:2.17.0'
//    implementation 'org.tensorflow:tensorflow-lite-gpu:2.17.0'
//    implementation "org.tensorflow:tensorflow-lite-support:0.4.4"
//
//    // ML Kit Object Detection
//    implementation 'com.google.mlkit:object-detection-common:18.0.0'

    // Nếu sau này cần GPU delegate plugin hoặc GPUImage thì mở comment, còn hiện tại nên bỏ
    // implementation 'org.tensorflow:tensorflow-lite-gpu-delegate-plugin:0.4.4'
    // implementation("jp.co.cyberagent.android:gpuimage:2.1.0")
}