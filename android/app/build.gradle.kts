import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("../.env")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}
val googleMapsApiKey = localProperties["GOOGLE_MAPS_API_KEY"] as String? ?: ""

android {
    namespace = "com.example.offroad_nav"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.offroad_nav"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        // ✅ Используем переменную из .env
        resValue("string", "google_maps_api_key", googleMapsApiKey)
    }

   // 1) Переопределяем стандартный debug-ключ, указывая общий keystore в репо
    signingConfigs {
        getByName("debug") {
            storeFile = file("$rootDir/team-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
 
    // 2) Явно используем этот же конфиг для debug и release (для удобных сборок)
    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false   // ← выключаем
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug") // пока так, для удобства
            isMinifyEnabled = false     // можно оставить false, тогда
            isShrinkResources = false   // и тут тоже выключаем
            // если захочешь включить shrink:
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
