pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // PERBAIKAN: Harus ke 8.9.1 karena library AndroidX (core, activity, browser) memintanya
    id("com.android.application") version "8.9.1" apply false
    
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.4.2" apply false
    // END: FlutterFire Configuration
    
    // Kotlin tetap di 1.9.20+ agar kompatibel dengan AGP terbaru
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
}

include(":app")