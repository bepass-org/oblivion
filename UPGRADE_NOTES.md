# Upgrade Notes

This file records dependency/toolchain upgrades and any required rollbacks or workarounds.

## 2026-08-16 — Full Android-side modernization pass

### Upgraded (all verified against live Maven/Google Maven metadata via `version_audit.ps1`)
- **Gradle:** 9.6.1 → **9.7.0** (wrapper)
- **AGP:** 9.3.0 → **9.3.1**
- **KSP:** 2.3.10 → **2.3.11**
- **Compose BOM:** 2026.06.01 → **2026.08.00** (Compose 1.11.4 → 1.12.0, material3 1.4.0)
- **OkHttp:** 5.4.0 → **5.5.0**
- **Okio:** 3.17.0 → **3.18.1**
- **MMKV:** 2.4.0 → **2.4.1**
- **Detekt:** 2.0.0-alpha.5 → **2.0.0-alpha.6**
- **Spotless:** 8.8.0 → **8.9.0**
- **Dependency Analysis:** 3.17.0 → **3.18.0**
- **CycloneDX:** 3.3.0 → **3.4.1**
- Kotlin 2.4.10, Hilt 2.60.1, Lifecycle 2.11.0, Navigation 2.9.8, Glide 5.0.9, Coroutines 1.11.0
  already latest stable and unchanged.

### Supply chain
- `gradle/verification-metadata.xml` regenerated for Gradle 9.7.0's kotlin-dsl 6.7.3 and all new
  versions; `org.apache:apache:39` pinned by cross-verified sha256 (local cache vs independent
  Maven Central download) because its signing key sits in the ignored-keys list on this network.
- `app/gradle.lockfile` re-persisted with `--write-locks` under STRICT locking.
- `buildSrc/build` artifacts untracked from git (already covered by `.gitignore`).

### Android platform compliance (documented APIs)
- VPN foreground service migrated from `specialUse` (+ subtype property, `VpnServicePolicy`
  lint suppression) to **`systemExempted`** with `FOREGROUND_SERVICE_SYSTEM_EXEMPTED`, matching
  the official foreground-service-types guidance for VPN apps; `startForeground` call updated.
- `themes.xml`: removed `statusBarColor`/`navigationBarColor`/`windowLight*` items deprecated by
  Android 15 edge-to-edge enforcement; `enableEdgeToEdge` remains the single source of truth.
- `Uri.parse` replaced with the KTX `String.toUri` extension (lint `UseKtx`).
- Deprecated `TileService.startActivityAndCollapse(Intent)` legacy branch documented and
  suppressed per lint waiver LINT-TILE-COLLAPSE-001 (API 24-33 fallback is unavoidable).

### Responsiveness (phones, tablets, foldables, desktop mode, TV)
- `OblivionApp` now wraps all destinations in a single-pane adaptive frame using the documented
  Material 3 window width breakpoints (compact <600 dp; medium/expanded capped at a 600 dp
  centered column). No new dependency: uses `BoxWithConstraints`, matching the existing
  `SplashScreen` pattern; `material3-adaptive` was evaluated and rejected (alpha-only, not in the
  Compose BOM). Phone (compact) layout is pixel-identical to before.
- TV: banner, LEANBACK_LAUNCHER, `leanback`/`touchscreen` feature declarations verified; focus
  traversal comes from standard Material3 clickable semantics.

### Dead code / resource removal (Android side only)
- Deleted unused sources: `utils/NetworkUtils`, `utils/LogFiles`, `utils/ColorUtils`,
  `utils/SystemUtils` (deprecated window APIs), `wireguard/WireGuardProfileRepository`,
  `ui/SettingsDialogs.EditValueDialog`, `MainActivity.start()`.
- Deleted unused resources: 6 unreferenced fonts (emoji/oxygen x3/shabnam-light/thin),
  `values/attrs.xml` (unused `Icon` styleable), empty `res/color`, `res/layout`,
  `res/values-night`, `res/values-television` dirs, and the empty nested
  `service/org/bepass/...` directory tree.
- ProGuard: removed 4 stale `base.*Initializer` keep rules; added the missing
  `-keep class hev.htproxy.TProxyService` rule that protects the name-based JNI binding under
  full-mode R8 repackaging.
- `TunnelEndpointPolicy` rewritten with named constants and split helpers to satisfy the zero
  Detekt findings gate (MagicNumber, ReturnCount); policy behavior unchanged and unit-tested.
- `EndpointSheet`: duplicate endpoint content is now rejected on save and `LazyColumn` rows use
  content keys; `SplitTunnelScreen` bitmap assertion `!!` replaced with null-safe `?.let`.

### Verification evidence (this pass)
- `compileOssDebugKotlin`/`compilePlayDebugKotlin` with Kotlin warnings-as-errors: PASS
- `testOssDebugUnitTest` + `testPlayDebugUnitTest`: PASS
- `detekt` zero findings, `spotlessCheck`, `lintOssDebug` (warningsAsErrors, one documented
  waiver pair): PASS under strict dependency verification
- Native core tasks were excluded (`-x buildNativeCore -x buildHev`) because pre-existing
  core-side edits (native/ + tun2socks inputs modified 2026-07-19) fail the pinned usque
  patch-hash gate against the AAR built 2026-07-16. That rebuild is core-side work and is
  intentionally untouched per project boundaries; see docs/PRODUCTION_GATES.md.

## 2026-06-21 — Gradle 9.6.0 Full Feature Adoption

### Upgraded
- **Gradle:** 9.5.0 → **9.6.0** (wrapper + distribution)
- **Compose BOM:** 2026.05.01 → **2026.06.01**
- **Core KTX:** 1.19.0-rc01 → **1.19.0** (stable)

### Gradle 9.6.0 Features Enabled
- **Configuration Cache:** Improved hit rates for project properties via system properties/env vars (auto-enabled)
- **`NO_IMPLICIT_LOOKUP_IN_PARENT_PROJECTS`** feature preview enabled in `settings.gradle.kts` (prepares for Gradle 10)
- **Performance optimizations** in `gradle.properties`: `org.gradle.parallel=true`, `org.gradle.vfs.watch=true`, `org.gradle.configuration-cache.problems=fail`, increased JVM heap (3GB daemon, 2GB Kotlin daemon)
- **CLI improvements:** `--non-interactive` support, `NO_COLOR` env var, sortable HTML test reports (auto)

### Deprecation Fixes (Gradle 10 Preparation)
- **Keystore loading migrated** from `Properties` + `inputStream()` to `OptionalPropertiesValueSource` (CC-compatible, lazy Provider API)
- **Removed deprecated Kotlin DSL delegated property** (`by providers.of(...)` → explicit `providers.of(...)`)
- **Verified no task action deprecations** (taskDependencies, getExtensions, injected Project/Gradle services)
- **Spotless 8.6.0** retained (8.7.0 available but CC compatibility unverified); explicit incompatibility removed

### Build Infrastructure
- **buildSrc:** Added JetBrains Kotlin EAP repository for plugin compatibility
- **Configuration Cache:** Verified working with cache storage and reuse (`help`, `tasks`, `versionAudit`)

### Known Considerations
- AGP 9.2.1 retained (9.3.0+ not yet stable)
- Hilt 2.59.2, Navigation Compose 2.10.0-alpha05, Lifecycle 2.11.0-rc01 retained (stable versions not yet released)
- Deprecation warning: "Using a Project object as a dependency notation" — likely from AGP/internal plugin, not project code
- `buildNeeded`/`buildDependents` tasks deprecated in Gradle 9.6 (will be removed in Gradle 10)

## 2026-06-20 — Tun2socks Core Reset

- Removed the local `tun2socks.aar` dependency and Gradle verification step.
- Reduced `tun2socks/` to a dependency-free placeholder module.
- Added a Kotlin `tun2socks` placeholder API so the Android app still compiles while failing fast if the absent core is started.
- Removed the stale `warp-plus` linkage from the Go module.

## 2026-06-14 — Comprehensive Version Audit & Fixes

### Current Versions (from actual project files)

| Component | Version | Status |
|-----------|---------|--------|
| **Gradle** | 9.5.0 | Latest stable |
| **AGP** | 9.2.1 | Latest stable |
| **Kotlin** | 2.3.21 | Latest stable |
| **KSP** | 2.3.9 | Compatible with Kotlin 2.3.21 |
| **JDK** | 25 | Toolchain + daemon |
| **NDK** | 29.0.14206865 | Stable |
| **Compose BOM** | 2026.05.01 | Latest |
| **Navigation Compose** | 2.10.0-alpha05 | Latest (alpha) |
| **Activity Compose/KTX** | 1.13.0 | Latest stable |
| **Core KTX** | 1.19.0-rc01 | Release candidate |
| **Lifecycle** | 2.11.0-rc01 | Release candidate |
| **Hilt** | 2.59.2 | Latest stable |
| **Hilt Navigation Compose** | 1.4.0-rc01 | Release candidate |
| **OkHttp** | 5.3.2 | Latest stable |
| **Coroutines** | 1.11.0 | Latest |
| **MMKV** | 2.4.0 | Latest stable |
| **Glide** | 5.0.7 | Latest stable |
| **Timber** | 5.0.1 | Latest stable |
| **Detekt** | 2.0.0-alpha.3 | Alpha (awaiting stable) |
| **Spotless** | 8.6.0 | Latest stable |
| **Dependency Analysis** | 3.14.0 | Latest stable |
| **Go (tun2socks)** | 1.24.1 | Module version |
| **compileSdk** | 37 | Preview SDK |
| **targetSdk** | 36 | Android 16 |
| **minSdk** | 24 | Android 7.0 |

### Changes Made
- Synchronized this document with actual version catalog (`gradle/libs.versions.toml`)
- Added google() repository to `buildSrc/build.gradle.kts` for AGP compatibility
- Fixed `compileSdk` consistency (37 → aligned with targetSdk documentation)
- Replaced direct `android.util.Log` calls with `Timber` throughout `OblivionVpnService.kt`
- Fixed ProGuard `-assumenosideeffects` for Log to avoid breaking Timber
- Refactored `tun2socks.go` to use struct-based encapsulation (eliminated global mutable state)
- Updated `tools:targetApi` in AndroidManifest.xml

### Known Considerations
- Several libraries use alpha/rc versions intentionally (bleeding-edge policy)
- Navigation Compose 2.10.0-alpha05: using latest features, stable expected soon
- Lifecycle 2.11.0-rc01: release candidate, stable imminent
- Detekt 2.0.0-alpha.3: major rewrite, alpha quality
- compileSdk 37 is a preview SDK; verify compatibility with AGP 9.2.1
- Go module at `go 1.24.1`; `tun2socks` is currently a dependency-free placeholder.

## 2026-04-25 (initial changes)

### Upgraded

#### Core Toolchain
- Kotlin: `2.3.20-RC` → `2.4.0` (later reverted, see final corrections)
- KSP: `2.3.6` → `2.4.0-1.0.31` (later aligned with Kotlin downgrade, see final corrections)
- AGP: `8.14.0` → `9.1.0` (`gradle/libs.versions.toml`)
- Gradle: `9.2.1` → `9.3.1` (wrapper + `gradle-wrapper.properties`)
- JDK: `21` → `25` (toolchain JVM, daemon JVM, `gradle.properties`)
- NDK: `29.0.14206865` (unchanged, but verified on AGP 9)

#### AndroidX & Compose
- Compose BOM: `2026.02.00` → `2026.04.00`
- Navigation Compose: `2.9.7` → `2.10.0-alpha01`
- Activity Compose: `1.13.0-alpha01` → `1.13.0-alpha02`
- Core KTX: `1.18.0-rc01` → `1.18.0`
- Lifecycle: `2.10.0` (unchanged)
- AppCompat: `1.7.1` → `1.7.2`
- Material Design: `1.14.0-alpha09` → `1.14.0-alpha10`
- ConstraintLayout: `2.2.1` (unchanged)
- Fragment: `1.8.9` (unchanged)
- Core Splashscreen: `1.2.0` (unchanged)
- ProfileInstaller: `1.4.1` (unchanged)

#### Plugin Dependencies
- Google Services: `4.4.4` → `4.4.5`
- Firebase Plugins: Crashlytics `3.0.6` → `3.0.7`; Perf `2.0.2` → `2.0.3`
- Detekt: `1.23.8` → `1.24.0`
- Spotless: `8.2.1` → `8.3.0`
- Dependency Analysis: `3.5.1` → `3.6.0`

#### Core Libraries
- Hilt: `2.59.2` (unchanged)
- OkHttp: `5.3.2` (unchanged)
- Coroutines: `1.10.2` (unchanged)
- MMKV: `2.3.0` (unchanged here; later bumped, see final corrections)
- Coil: `3.3.0` → `3.4.0-alpha01`

### Massive Java to Kotlin Migration
- Converted all remaining Java source files to Kotlin, including:
  - `ApplicationLoader` (now fully Hilt-aware, with proper error isolation and Timber logging)
  - `BaseActivity`, `StateAwareBaseActivity`
  - All activities: `MainActivity`, `SettingsActivity`, `LogActivity`, `SplashScreenActivity`, `SplitTunnelActivity`, `InfoActivity`
  - All adapters: `BypassListAppsAdapter`, `EndpointsBottomSheet`, `SplitTunnelOptionsAdapter`
  - Utility classes: `FileManager`, `SystemUtils`, `ColorUtils`, `LocaleManager`, `HostPortParser`, etc.
  - Custom views: `Icon`, `TouchAwareSwitch`
  - DNS and network modules: `NetworkModule`, `DnsUriParserTest`, `DnsExecutionPlannerTest`, etc.
  - Build-time classes: `FileExistsValueSource`, `OptionalPropertiesValueSource`
  - Removed all Java sources; project is now fully Kotlin-based.
- Updated `app/build.gradle` to use `alias(libs...)` exclusively for plugins and dependencies.
- Removed deprecated `vectorDrawables.useSupportLibrary` and redundant `buildConfig` flag from `app/build.gradle`.
- Migrated release signing configuration from hardcoded values to external `keystore.properties` (gitignored), with a `validateReleaseSigning` task.
- Previously rewrote gomobile task wiring; that native-core path was removed by the 2026-06-20 reset.
- Switched `FileManager.initialize` call from `BaseActivity` to `ApplicationLoader` to avoid redundant initialisation.
- Refactored `FileManager` into a singleton `object`, added `Keys` constants, and replaced manual locking with `ReentrantReadWriteLock`.
- Centralised all VPN configuration building in `FileManager.getVpnConfig()` under a single read-lock for consistency.

### Lint & Code Quality
- Lint baseline (`lint-baseline.xml`) completely emptied after fixing all reported issues:
  - Updated dependency versions.
  - Removed unused resources (drawables, colors, strings, dimensions/styles, arrays).
  - Fixed icon density issues and removed redundant `png` copies in favour of `anydpi` vector drawables.
  - Replaced `LinearLayout` in `toast.xml` with a single `TextView` using compound drawables.
  - Removed overdraw on root elements by relying on theme backgrounds.
  - Hardcoded endpoint text moved to string resources.
- Upgraded `detekt.yml` to the latest official baseline, updated rule names and properties.
- **Deleted the lint baseline file entirely** (zero lint warnings now).
- Removed `gradle-versions-plugin` because it crashes on this Gradle/AGP stack.
  Use `version_audit.ps1` instead.

### ProGuard / R8
- Rewrote `proguard-rules.pro` with modern best practices:
  - Enabled line number retention and source file renaming for Crashlytics visibility.
  - Added `-assumenosideeffects` to strip `android.util.Log` calls in release builds.
  - Previously retained native library rules; those rules were removed by the 2026-06-20 reset.

### Build Infrastructure
- Updated `gradle.properties`:
  - JVM args: `-Xmx2048M` (from 1536M); removed obsolete `-XX:MaxPermSize`.
  - Enabled parallel builds (`org.gradle.parallel=true`).
  - Set `org.gradle.warning.mode=all`.
  - Added `android.builtInKotlin=true` for AGP 9.x (though it is the default, explicit is safer).
  - `android.enableR8.fullMode=true` kept for clarity (default since AGP 8).
- Updated wrapper scripts (`gradlew`, `gradlew.bat`, `gradle-wrapper.properties`) to match the current Gradle wrapper version.
- Updated `devshell.nix` and `flake.nix` to target JDK 26 and Go 1.26 for future‑proofing (the project still compiles with JDK 25).
- Updated `version_audit.ps1` to compare against the **latest stable** Gradle version (not RCs), avoiding false positives.
- Revised `.gitignore` to track new build artifacts and Kotlin caches properly.

### Configuration & App Manifest
- Overhauled `AndroidManifest.xml`:
  - Added `android:foregroundServiceType="dataSync|specialUse"` and the corresponding `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` to the VPN service (required since Android 14).
  - Removed the dangerous `QUERY_ALL_PACKAGES` permission; kept only safe `<queries>` entries.
  - Ensured compatibility with Predictive Back gesture on Android 16+.
  - Removed deprecated `usesCleartextTraffic` attribute; network security is now controlled exclusively via `networkSecurityConfig`.
- Redesigned `dns_providers.json` into a structured catalog (`pinned`, `verified`, `community`) with Iranian providers, `selectionWeight` fields, and health‑check rules for the custom DNS engine.
- Resolved Git conflict in `dimens.xml`, keeping all spacing and radius tokens with proper documentation.

### Core Tunnel (Go) — tun2socks.go
- Complete rewrite of the tunnel core for safety and resource hygiene:
  - Eliminated global mutable state; all lifecycle is now managed by a `Tunnel` struct.
  - Added `Start`/`Wait`/`Stop` non‑blocking semantics with proper goroutine draining.
  - Added panic recovery in the main worker goroutine with full stack‑trace logging.
  - Capturing stdout/stderr is done with `os.Pipe`; both are restored cleanly on shutdown.
  - Used `sync.Pool` for zero‑allocation log pipeline buffers.
  - Input validation (`validateOptions`) reports all errors at once using `errors.Join`.
  - All file descriptors and goroutines are guaranteed to be released before `Stop` returns.

## 2026-04-25 (final corrections — post‑audit)

### Version Corrections
- **Kotlin:** `2.4.0` reverted to `2.3.21` — `2.4.0` is not yet released (planned June‑July 2026).
- **KSP:** `2.4.0-1.0.31` → `2.3.21-1.0.31` (aligned with Kotlin downgrade).
- **Gradle:** `9.3.1` → `9.4.1` — latest stable as of late April 2026.
- **MMKV:** `2.3.0` → `2.4.0` (released March 2026).
- **Coil:** `3.4.0-alpha01` → `3.4.0` (stable release).
- **Navigation Compose:** `2.10.0-alpha01` → `2.9.7` (reverted to stable; the alpha is not recommended for production).
- **Spotless:** `8.3.0` → `8.4.0` (latest release).
- **Go (devshell):** `1.25` → `1.26.1` (latest stable; aligned with `devshell.nix`).
- **JDK (devshell):** `25` → `26` (aligned with `devshell.nix`; the project's compilation toolchain remains on JDK 25 until full validation).

### Config Adjustments
- Added `android.builtInKotlin=true` to `gradle.properties` (explicit for AGP 9.x).
- Updated `Gradle_Playbook.md` and `devshell.nix` to reflect final version numbers.
- Finalised `tun2socks.go` with all reviewed improvements (race‑condition fix, panic recovery, stdout/stderr capture hygiene, resource‑pool cleanup).
- Updated `flake.nix` to pin NDK 29.0.14206865 (matching the project) and JDK 26.

### Notes
- Kotlin `2.4.0` should be adopted when it reaches stable (target: mid‑2026).
- Gradle `9.4.1` officially supports JDK 26, but the project's compilation toolchain remains on JDK 25 until all dependencies are verified against JDK 26.
- The dependency analysis plugin (`com.autonomousapps.dependency-analysis`) stays at `3.6.0` — no newer stable version available.
- All Java files have been deleted and the project is now **100% Kotlin** (including `buildSrc` and tests). No Java source remains.
