import java.util.Properties

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

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

val selectedAbis: Map<String, String> = when {
    requestedAbis.isEmpty() -> abiTargets
    else -> abiTargets.filterKeys(requestedAbis::contains)
}

val aetherCoreDir = file("../../aetherproject/aether")

val ndkRelease = (project.findProperty("ndkVersion") as String?)
    ?: System.getenv("ANDROID_NDK_VERSION")
    ?: "29.0.13846066"

android {
    namespace = "org.bepass.oblivion.vpn"
    compileSdk = 37
    ndkVersion = ndkRelease

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
        ndk {
            abiFilters.addAll(selectedAbis.keys)
        }
    }

    externalNativeBuild {
        ndkBuild {
            path = file("src/main/jni/Android.mk")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
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
    api(project(":psiphon"))
}

fun sdkDirectory(): File? {
    for (key in listOf("ANDROID_HOME", "ANDROID_SDK_ROOT")) {
        val value = System.getenv(key)
        if (value != null && file(value).exists()) return file(value)
    }

    val properties = rootProject.file("local.properties")
    if (properties.exists()) {
        val loaded = Properties()
        properties.inputStream().use { loaded.load(it) }
        val configured = loaded.getProperty("sdk.dir")
        if (configured != null && file(configured).exists()) return file(configured)
    }
    return null
}

fun resolveNdkDir(): File? {
    for (key in listOf("ANDROID_NDK_HOME", "NDK_HOME")) {
        val value = System.getenv(key)
        if (value != null && file(value).exists()) return file(value)
    }

    val sdkDir = sdkDirectory() ?: return null
    val versioned = File(sdkDir, "ndk/$ndkRelease")
    if (versioned.exists()) return versioned

    return File(sdkDir, "ndk").listFiles()
        ?.filter { it.isDirectory }
        ?.maxByOrNull { it.name }
}

fun hostTag(ndkDir: File): String {
    val os = System.getProperty("os.name").lowercase()
    val arch = System.getProperty("os.arch").lowercase()

    val preferred = when {
        os.contains("mac") && (arch.contains("aarch64") || arch.contains("arm")) ->
            listOf("darwin-arm64", "darwin-x86_64")
        os.contains("mac") -> listOf("darwin-x86_64", "darwin-arm64")
        os.contains("win") -> listOf("windows-x86_64")
        arch.contains("aarch64") || arch.contains("arm") ->
            listOf("linux-arm64", "linux-x86_64")
        else -> listOf("linux-x86_64", "linux-arm64")
    }

    val prebuilt = File(ndkDir, "toolchains/llvm/prebuilt")
    for (candidate in preferred) {
        if (File(prebuilt, candidate).isDirectory) return candidate
    }

    val found = prebuilt.listFiles()?.firstOrNull { it.isDirectory }?.name
    if (found != null) {
        logger.lifecycle("[aether] using the only ndk toolchain present: $found")
        return found
    }

    return preferred.first()
}

fun runCommand(
    command: List<String>,
    workingDir: File,
    extraEnvironment: Map<String, String> = emptyMap(),
): Pair<Int, String> {
    val builder = ProcessBuilder(command)
        .directory(workingDir)
        .redirectErrorStream(true)
    builder.environment().putAll(extraEnvironment)

    val process = builder.start()
    val output = process.inputStream.bufferedReader().readText()
    return process.waitFor() to output
}

val buildAetherCore by tasks.registering {
    group = "aether"
    description = "Cross compiles the Aether Rust core for every Android ABI"

    val outputDir = file("src/main/jniLibs")
    outputs.dir(outputDir)

    inputs.dir(File(aetherCoreDir, "src"))
    inputs.file(File(aetherCoreDir, "Cargo.toml"))
    inputs.property("abis", selectedAbis.keys.sorted().joinToString(","))

    doLast {
        val destRoot = outputDir
        destRoot.mkdirs()

        if (!aetherCoreDir.exists()) {
            throw GradleException(
                "Aether core sources not found at ${aetherCoreDir.absolutePath}",
            )
        }

        val (cargoStatus, cargoOutput) =
            runCommand(listOf("cargo", "--version"), aetherCoreDir)
        if (cargoStatus != 0) {
            throw GradleException(
                "cargo is not usable, install the Rust toolchain: $cargoOutput",
            )
        }

        val ndkDir = resolveNdkDir()
            ?: throw GradleException("Android NDK not found, set ANDROID_NDK_HOME")
        val toolchainBin = File(ndkDir, "toolchains/llvm/prebuilt/${hostTag(ndkDir)}/bin")
        val apiLevel = 24

        logger.lifecycle("[aether] building for ${selectedAbis.keys.joinToString(", ")}")

        for (stale in abiTargets.keys - selectedAbis.keys) {
            val staleDir = File(destRoot, stale)
            if (staleDir.exists()) {
                logger.lifecycle("[aether] dropping the stale $stale core")
                staleDir.deleteRecursively()
            }
        }

        for ((abi, triple) in selectedAbis) {
            val clangName = when (abi) {
                "armeabi-v7a" -> "armv7a-linux-androideabi$apiLevel-clang"
                else -> "$triple$apiLevel-clang"
            }
            val clang = File(toolchainBin, clangName)
            if (!clang.exists()) {
                throw GradleException("NDK clang not found: ${clang.absolutePath}")
            }

            val envTriple = triple.uppercase().replace('-', '_')
            val sysroot = File(toolchainBin, "../sysroot").canonicalFile
            // The clang target the versioned wrapper resolves to, e.g.
            // aarch64-linux-android24 for aarch64-linux-android24-clang.
            val clangTarget = clangName.removeSuffix("-clang")

            val environment = mapOf(
                "ANDROID_NDK_HOME" to ndkDir.absolutePath,
                "ANDROID_NDK_ROOT" to ndkDir.absolutePath,
                "CARGO_TARGET_${envTriple}_LINKER" to clang.absolutePath,
                "CARGO_TARGET_${envTriple}_RUSTFLAGS" to
                    "-C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384",
                // CC must be the unversioned clang: boring-sys forwards it to
                // CMake as CMAKE_C_COMPILER, and the NDK toolchain file caches
                // the unversioned clang. A versioned wrapper makes BoringSSL's
                // second configure think the compiler changed, so CMake wipes
                // its cache and reconfigures against the macOS host SDK.
                // The API level is kept via the --target flag below instead.
                "CC_${triple.replace('-', '_')}" to
                    File(toolchainBin, "clang").absolutePath,
                "CXX_${triple.replace('-', '_')}" to
                    File(toolchainBin, "clang++").absolutePath,
                "CFLAGS_${triple.replace('-', '_')}" to "--target=$clangTarget",
                "CXXFLAGS_${triple.replace('-', '_')}" to "--target=$clangTarget",
                "AR_${triple.replace('-', '_')}" to
                    File(toolchainBin, "llvm-ar").absolutePath,
                "BINDGEN_EXTRA_CLANG_ARGS_${triple.replace('-', '_')}" to
                    "--target=$triple --sysroot=${sysroot.absolutePath}",
                "RUST_LIBC_UNSTABLE_MUSL_V1_2_3" to "1",
            )

            // A BoringSSL CMake cache left by a previous run (or restored by
            // CI) can record different compiler settings; CMake then deletes
            // the cache mid-configure and loses the NDK toolchain, silently
            // building host-architecture objects. The archives live inside
            // that cache, so it is only ever dropped together with the
            // fingerprint: cargo would otherwise call boring-sys fresh, skip
            // the build script, and leave quiche linking an ssl that is gone.
            val releaseDir = File(aetherCoreDir, "target/$triple/release")
            val wantedCompiler = File(toolchainBin, "clang").absolutePath

            fun boringSysIn(group: String) = File(releaseDir, group)
                .listFiles()
                ?.filter { it.name.startsWith("boring-sys-") }
                .orEmpty()

            val boringBuilds = boringSysIn("build")
            val healthy = boringBuilds.filter { candidate ->
                val out = File(candidate, "out/build")
                if (!File(out, "libssl.a").isFile) return@filter false
                if (!File(out, "libcrypto.a").isFile) return@filter false

                val cache = File(out, "CMakeCache.txt")
                if (!cache.isFile) return@filter false
                val recorded = cache.readLines()
                    .firstOrNull { it.startsWith("CMAKE_C_COMPILER:") }
                    ?.substringAfter('=')
                recorded == null || recorded == wantedCompiler
            }

            val orphanFingerprint =
                boringBuilds.isEmpty() && boringSysIn(".fingerprint").isNotEmpty()

            if (healthy.size != boringBuilds.size || orphanFingerprint) {
                logger.lifecycle("[aether] the boringssl cache for $abi is stale, rebuilding it")
                boringBuilds.forEach { it.deleteRecursively() }
                boringSysIn(".fingerprint").forEach { it.deleteRecursively() }
            }

            logger.lifecycle("[aether] building the core for $abi ($triple)")
            val (status, output) = runCommand(
                listOf("cargo", "build", "--release", "--target", triple, "--bin", "aether"),
                aetherCoreDir,
                environment,
            )
            if (status != 0) {
                throw GradleException("cargo failed for $abi:\n$output")
            }

            val produced = File(aetherCoreDir, "target/$triple/release/aether")
            if (!produced.exists()) {
                throw GradleException(
                    "aether binary missing for $abi: ${produced.absolutePath}",
                )
            }

            val abiDir = File(destRoot, abi).apply { mkdirs() }
            produced.copyTo(File(abiDir, "libaether.so"), overwrite = true)
        }
    }
}


tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }
    .configureEach { dependsOn(buildAetherCore) }
