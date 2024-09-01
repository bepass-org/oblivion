package org.bepass.oblivion.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;

import com.tencent.mmkv.MMKV;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class FileManager {

    private static MMKV mmkv;
    private static final Lock lock = new ReentrantLock();

    public static class KeyHolder {
        public static final String DARK_MODE = "setting_dark_mode";
        // Add more keys as needed
    }

    /**
     * Initializes the MMKV instance with the provided application context.
     * This should be called in the application class or before using MMKV.
     *
     * @param context The application context
     */
    public static void initialize(Context context) {
        lock.lock();
        try {
            if (mmkv == null) {
                MMKV.initialize(context.getApplicationContext());
                mmkv = MMKV.mmkvWithID("UserData");
            }
        } finally {
            lock.unlock();
        }
    }

    // ===========================================================================
    // Methods for setting various data types with synchronization

    public static void set(String name, String value) {
        lock.lock();
        try {
            checkInitialized();
            mmkv.encode(name, value);
        } finally {
            lock.unlock();
        }
    }

    public static void set(String name, boolean value) {
        lock.lock();
        try {
            checkInitialized();
            mmkv.encode(name, value);
        } finally {
            lock.unlock();
        }
    }

    public static void set(String name, Set<String> value) {
        lock.lock();
        try {
            checkInitialized();
            mmkv.encode(name, value);
        } finally {
            lock.unlock();
        }
    }

    public static void set(String name, int value) {
        lock.lock();
        try {
            checkInitialized();
            mmkv.encode(name, value);
        } finally {
            lock.unlock();
        }
    }

    public static void set(String name, float value) {
        lock.lock();
        try {
            checkInitialized();
            mmkv.encode(name, value);
        } finally {
            lock.unlock();
        }
    }

    public static void set(String name, long value) {
        lock.lock();
        try {
            checkInitialized();
            mmkv.encode(name, value);
        } finally {
            lock.unlock();
        }
    }

    // ===========================================================================
    // Methods for getting various data types with synchronization

    public static String getString(String name) {
        lock.lock();
        try {
            checkInitialized();
            return mmkv.decodeString(name, "");
        } finally {
            lock.unlock();
        }
    }

    public static String getString(String name, String defaultValue) {
        lock.lock();
        try {
            checkInitialized();
            return mmkv.decodeString(name, defaultValue);
        } finally {
            lock.unlock();
        }
    }

    public static Set<String> getStringSet(String name, Set<String> def) {
        lock.lock();
        try {
            checkInitialized();
            Set<String> result = mmkv.decodeStringSet(name, null);
            return result != null ? result : def;
        } finally {
            lock.unlock();
        }
    }

    public static boolean getBoolean(String name) {
        lock.lock();
        try {
            checkInitialized();
            return mmkv.decodeBool(name, false);
        } finally {
            lock.unlock();
        }
    }

    public static boolean getBoolean(String name, boolean defaultValue) {
        lock.lock();
        try {
            checkInitialized();
            return mmkv.decodeBool(name, defaultValue);
        } finally {
            lock.unlock();
        }
    }

    public static int getInt(String name) {
        lock.lock();
        try {
            checkInitialized();
            return mmkv.decodeInt(name, 0);
        } finally {
            lock.unlock();
        }
    }

    // ===========================================================================
    // Methods for resetting data with synchronization

    public static void resetToDefault() {
        lock.lock();
        try {
            checkInitialized();
            mmkv.clearAll();
            mmkv.encode(KeyHolder.DARK_MODE, false);
        } finally {
            lock.unlock();
        }
    }

    public static void cleanOrMigrateSettings(Context context) {
        lock.lock();
        try {
            checkInitialized();
            {
                SharedPreferences old_man = context.getSharedPreferences("UserData", Context.MODE_PRIVATE);
                mmkv.importFromSharedPreferences(old_man);
                old_man.edit().clear().commit();
            }
            if (!getBoolean("isFirstValueInit")) {
                set("USERSETTING_endpoint", "engage.cloudflareclient.com:2408");
                set("USERSETTING_port", "8086");
                set("USERSETTING_gool", false);
                set("USERSETTING_psiphon", false);
                set("USERSETTING_lan", false);
                set("USERSETTING_proxymode", false);
                set("USERSETTING_endpoint_type", 0);
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
        } finally {
            lock.unlock();
        }
    }

    // ===========================================================================
    // Helper Methods

    private static void checkInitialized() {
        if (mmkv == null) {
            throw new IllegalStateException("MMKV is not initialized. Call FileManager.initialize(Context) first.");
        }
    }
}