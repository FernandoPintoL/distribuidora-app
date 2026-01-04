import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.distribuidora.paucara.distribuidora"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = false
        unitTests.isReturnDefaultValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
        freeCompilerArgs += listOf("-Xjvm-default=all")
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.distribuidora.paucara.distribuidora"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Leer la API key de Google Maps desde el archivo .env
        val envFile = rootProject.file("../.env")
        val properties = Properties()

        if (envFile.exists()) {
            properties.load(FileInputStream(envFile))
        }

        val mapsApiKey = properties.getProperty("GOOGLE_MAPS_API_KEY")
            ?: System.getenv("GOOGLE_MAPS_API_KEY")
            ?: "YOUR_API_KEY_HERE"

        resValue("string", "MAPS_API_KEY", mapsApiKey)
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ⚠️ COMENTADO: Esta configuración puede causar conflictos con mobile_scanner
// Si el scanner no funciona, descomentar y ajustar las versiones según sea necesario
/*
configurations.all {
    resolutionStrategy {
        // Use stable camera versions for mobile_scanner compatibility
        force("androidx.camera:camera-core:1.3.4")
        force("androidx.camera:camera-camera2:1.3.4")
        force("androidx.camera:camera-lifecycle:1.3.4")
    }
}
*/

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
    implementation("org.jspecify:jspecify:0.3.0")

    // Camera dependencies for mobile_scanner
    implementation("androidx.camera:camera-core:1.3.4")
    implementation("androidx.camera:camera-camera2:1.3.4")
    implementation("androidx.camera:camera-lifecycle:1.3.4")
}

flutter {
    source = "../.."
}
