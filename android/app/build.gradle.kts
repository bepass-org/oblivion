
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

val hasReleaseKey = signingProperties.getProperty("storeFile") != null

val abiTargets = mapOf(
    "arm64-v8a" to "aarch64-linux-android",
    "armeabi-v7a" to "armv7-linux-androideabi",
    "x86_64" to "x86_64-linux-android",
)

val platformAbis = mapOf(
    "android-arm64" to "arm64-v8a",
    "android-arm" to "armeabi-v7a",
    "android-x64" to "x86_64",
)

val requestedAbis: List<String> = listOfNotNull(
    project.findProperty("aetherAbi") as String?,
    project.findProperty("target-platform") as String?,
)
    .flatMap { it.split(',') }
    .map { it.trim() }
    .mapNotNull { platformAbis[it] ?: it.takeIf(abiTargets::containsKey) }
    .distinct()

val selectedAbis: Set<String> = when {
    requestedAbis.isEmpty() -> abiTargets.keys
    else -> abiTargets.keys.filter(requestedAbis::contains).toSet()
}


android {
    namespace = "org.bepass.oblivion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = (project.findProperty("ndkVersion") as String?)
        ?: System.getenv("ANDROID_NDK_VERSION")
        ?: flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.bepass.oblivion"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.addAll(selectedAbis)
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
                enableV4Signing = false
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = when (hasReleaseKey) {
                true -> signingConfigs.getByName("release")
                false -> signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation(project(":aether-vpn"))
}

flutter {
    source = "../.."
}
