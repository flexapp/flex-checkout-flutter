plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.flex.checkout.flutter"
    compileSdk = 35

    defaultConfig {
        minSdk = 26
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        named("main") {
            java.srcDirs("src/main/kotlin")
        }
    }
}

dependencies {
    implementation("com.github.flexapp:flex-checkout-android:1.5.0")
}
