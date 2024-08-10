package org.bepass.oblivion.utils;

import android.content.Context;
import android.content.pm.PackageManager;

import com.tencent.mmkv.MMKV;

import java.util.HashSet;
import java.util.Set;

public class FileManager {
    private static MMKV mmkv;

    public static class KeyHolder {
        public static String DARK_MODE = "setting_dark_mode";
        // Add more keys as needed
    }

    public static void initialize(Context context) {
        MMKV.initialize(context.getApplicationContext());
        mmkv = MMKV.defaultMMKV();
    }

    // ===========================================================================
    // Methods for setting various data types with synchronization

    public static synchronized void set(String name, String value) {
        checkInitialized();
        mmkv.encode(name, value);
    }

    public static synchronized void set(String name, boolean value) {
        checkInitialized();
        mmkv.encode(name, value);
    }

    public static synchronized void set(String name, Set<String> value) {
        checkInitialized();
        mmkv.encode(name, new HashSet<>(value));
    }

    public static synchronized void set(String name, int value) {
        checkInitialized();
        mmkv.encode(name, value);
    }

    public static synchronized void set(String name, float value) {
        checkInitialized();
        mmkv.encode(name, value);
    }

    public static synchronized void set(String name, long value) {
        checkInitialized();
        mmkv.encode(name, value);
    }

    //    public static synchronized void setDouble(String name, double value) {
    //        checkInitialized();
    //        mmkv.encode(name, Double.doubleToRawLongBits(value));
    //    }

    // ===========================================================================
    // Methods for getting various data types with synchronization

    public static synchronized String getString(String name) {
        checkInitialized();
        return mmkv.decodeString(name, "");
    }

    public static synchronized String getString(String name, String defaultValue) {
        checkInitialized();
        return mmkv.decodeString(name, defaultValue);
    }

    public static synchronized Set<String> getStringSet(String name, Set<String> def) {
        checkInitialized();
        Set<String> result = mmkv.decodeStringSet(name, null);
        return result != null ? result : def;
    }

    public static synchronized boolean getBoolean(String name) {
        checkInitialized();
        return mmkv.decodeBool(name, false);
    }

    public static synchronized boolean getBoolean(String name, boolean defaultValue) {
        checkInitialized();
        return mmkv.decodeBool(name, defaultValue);
    }

    public static synchronized int getInt(String name) {
        checkInitialized();
        return mmkv.decodeInt(name, 0);
    }

    //    public static synchronized float getFloat(String name) {
    //        checkInitialized();
    //        return mmkv.decodeFloat(name, 0f);
    //    }
    //
    //    public static synchronized long getLong(String name) {
    //        checkInitialized();
    //        return mmkv.decodeLong(name, 0L);
    //    }
    //
    //    public static synchronized double getDouble(String name) {
    //        checkInitialized();
    //        return Double.longBitsToDouble(mmkv.decodeLong(name, 0L));
    //    }

    // ===========================================================================
    // Methods for resetting data with synchronization

    public static synchronized void resetToDefault() {
        checkInitialized();
        mmkv.clearAll();
        mmkv.encode(KeyHolder.DARK_MODE, false);
    }

    public static synchronized void cleanOrMigrateSettings(Context context) {
        checkInitialized();
        if (!getBoolean("isFirstValueInit")) {
            set("USERSETTING_endpoint", "engage.cloudflareclient.com:2408");
            set("USERSETTING_port", "8086");
            set("USERSETTING_gool", false);
            set("USERSETTING_psiphon", false);
            set("USERSETTING_lan", false);
            set("USERSETTING_proxymode", false);
            set("isFirstValueInit", true);
        }

        Set<String> splitApps = getStringSet("splitTunnelApps", new HashSet<>());
        Set<String> shouldKeep = new HashSet<>();
        final PackageManager pm = context.getApplicationContext().getPackageManager();
        for (String packageName : splitApps) {
            try {
                pm.getPackageInfo(packageName, PackageManager.GET_META_DATA);
            } catch (PackageManager.NameNotFoundException ignored) {
                continue;
            }
            shouldKeep.add(packageName);
        }
        set("splitTunnelApps", shouldKeep);
    }

    // ===========================================================================
    // Helper Methods

    private static void checkInitialized() {
        if (mmkv == null) {
            throw new IllegalStateException("MMKV is not initialized. Call FileManager.initialize(Context) first.");
        }
    }
}