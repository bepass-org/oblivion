val prebuilt = file("ca.psiphon.aar")

if (!prebuilt.exists()) {
    throw GradleException(
        "ca.psiphon.aar is missing at ${prebuilt.absolutePath}. " +
            "Build it with tools/build-psiphon-aar.sh, which needs a checkout of " +
            "CluvexStudio/psiphon-tunnel-core (branch shirokhorshid) next to this repo " +
            "and ANDROID_NDK_HOME pointing at the ndk.",
    )
}

configurations.maybeCreate("default")

artifacts.add("default", prebuilt)
