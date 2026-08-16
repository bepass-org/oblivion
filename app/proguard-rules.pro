# ── R8 Full-Mode Optimizations ────────────────────────────────
-repackageclasses ''
-allowaccessmodification
-optimizationpasses 3
-mergeinterfacesaggressively
-overloadaggressively

# ── Essential Attributes ───────────────────────────────────────
-keepattributes Exceptions,Signature,InnerClasses,Deprecated,AnnotationDefault
-keepattributes SourceFile,LineNumberTable,EnclosingMethod
-keepattributes *Annotation*,RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations
-keepattributes RuntimeVisibleTypeAnnotations,StackMapTable
-renamesourcefileattribute SourceFile

# ── tun2socks / Go JNI Bridge ─────────────────────────────────
-keep class tun2socks.** { *; }
-keep class go.** { *; }
-keep class * implements go.Seq.Proxy { *; }
-keepclassmembers class * {
    native <methods>;
    *** goSeqRef;
    *** ref;
}
-dontwarn tun2socks.**
-dontwarn go.**

# ── hev-socks5-tunnel JNI bridge (name-based native binding) ──
-keep class hev.htproxy.TProxyService { *; }

# ── Messenger IPC ─────────────────────────────────────────────
-keep class org.bepass.oblivion.service.OblivionVpnService$IncomingHandler { *; }
-keep class org.bepass.oblivion.service.OblivionVpnService { *; }
-keep class org.bepass.oblivion.service.QuickStartService { *; }
-keepclassmembers class android.os.Handler {
    public void handleMessage(android.os.Message);
}

# ── Dagger Hilt (Supplementary) ───────────────────────────────
-keep class * implements dagger.internal.DoubleCheck { *; }
-keep class * implements javax.inject.Provider { *; }
-keep class * implements dagger.MembersInjector { *; }
-keep class **_HiltModules* { *; }
-keep @dagger.hilt.EntryPoint class * { *; }
-keep @dagger.hilt.internal.GeneratedEntryPoint class * { *; }
-keep @dagger.hilt.DefineComponent class * { *; }
-dontwarn dagger.hilt.internal.aggregatedroot.**

# ── MMKV (JNI) ────────────────────────────────────────────────
-keep class com.tencent.mmkv.** { *; }
-keepclassmembers class com.tencent.mmkv.MMKV {
    native <methods>;
    *** onContentChangedByOuterProcess(...);
}

# ── Glide 5.x (Supplementary) ────────────────────────────────
-keep public class * extends com.github.bumptech.glide.module.AppGlideModule {
    public <init>();
}
-keep public class * extends com.github.bumptech.glide.module.LibraryGlideModule {
    public <init>();
}
-keep public enum com.github.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}
-keep class com.github.bumptech.glide.load.data.ParcelFileDescriptorRewinder$InternalRewinder {
    *** rewind();
}

# ── Kotlin Coroutines ─────────────────────────────────────────
-keep class kotlinx.coroutines.android.AndroidDispatcherFactory { *; }
-keep class kotlinx.coroutines.android.AndroidExceptionPreHandler { *; }
-dontwarn kotlinx.coroutines.debug.**
-dontwarn kotlinx.coroutines.internal.DiagnosticCoroutineContextException

# ── Kotlinx Serialization ─────────────────────────────────────
-keepclassmembers @kotlinx.serialization.Serializable class ** {
    static ** Companion;
}
-if @kotlinx.serialization.internal.NamedCompanion class *
-keepclassmembers class * { static <1> *; }
-if @kotlinx.serialization.Serializable class ** { static **$* *; }
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}
-if @kotlinx.serialization.Serializable class ** { public static ** INSTANCE; }
-keepclassmembers class <1> {
    public static <1> INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}
-keepclassmembers public class **$$serializer { private ** descriptor; }
-dontnote kotlinx.serialization.**
-dontwarn kotlinx.serialization.internal.ClassValueReferences

# ── App Domain Models, Enums, Parcelable ──────────────────────
-keep class org.bepass.oblivion.model.** { *; }
-keep class org.bepass.oblivion.enums.** { *; }
-keep class org.bepass.oblivion.ui.AppRoute { *; }

# DNS data classes (serialized via org.json)
-keep class org.bepass.oblivion.dns.DnsProfile { *; }
-keep class org.bepass.oblivion.dns.DnsSelection { *; }
-keep class org.bepass.oblivion.dns.DnsCatalog { *; }
-keep class org.bepass.oblivion.dns.DnsProvider { *; }
-keep class org.bepass.oblivion.dns.DnsRuntimePlan { *; }
-keep class org.bepass.oblivion.dns.AppDnsRuntimeConfig { *; }
-keep class org.bepass.oblivion.dns.DnsEndpoint { *; }
-keepclassmembers enum org.bepass.oblivion.dns.** {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable CREATORs
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Generic enum keep (covers any enum passed via Serializable/Bundle)
-keepclassmembers,allowobfuscation,allowshrinking enum * {
    **[] $VALUES;
    public *;
}

# ── Release Logging Security ──────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}
-assumenosideeffects class timber.log.Timber {
    public static void v(...);
    public static void d(...);
    public static void v(java.lang.Throwable, java.lang.String, java.lang.Object[]);
    public static void d(java.lang.Throwable, java.lang.String, java.lang.Object[]);
}

# ── Suppressed Warnings ───────────────────────────────────────
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn org.apache.harmony.xnet.provider.jsse.**
-dontwarn org.codehaus.mojo.animal_sniffer.*
-dontwarn okio.**
-dontnote okhttp3.internal.**
-dontnote okio.**
-dontnote com.tencent.mmkv.**
