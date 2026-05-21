plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.couchbase.quickstart"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
     }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
     }

    defaultConfig {
        applicationId = "com.couchbase.quickstart"
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
     }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
         }
     }
}

flutter {
    source = "../.."
}

dependencies {
     // Couchbase Lite
    implementation("com.couchbase.lite:couchbase-lite-android-ktx:4.0.3")

     // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0")
}
