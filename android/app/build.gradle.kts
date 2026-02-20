plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aplikasi_kost"
    
    // Tetap di 36 sesuai permintaan plugin-plugin terbaru Anda
    compileSdk = 36
    
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Mendukung fitur Java modern untuk flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.aplikasi_kost"
        
        // PERBAIKAN: Gunakan penetapan eksplisit agar tidak tertimpa automigrasi
        val customMinSdk = 23
        minSdk = customMinSdk
        
        // Target harus sinkron dengan compileSdk
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            // Nonaktifkan minify jika Anda belum mengatur Proguard untuk Firebase/Notifications
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Menggunakan signing debug agar bisa build tanpa keystore manual
            signingConfig = signingConfigs.getByName("debug")
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // PERBAIKAN: Versi 2.1.4 diwajibkan oleh AGP 8.9.1
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    implementation("androidx.multidex:multidex:2.0.1")
}