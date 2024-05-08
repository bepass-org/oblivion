package org.bepass.oblivion;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.Set;

public class FileManager {
    private static FileManager instance;
    private final SharedPreferences sharedPreferences;

    // Private constructor for singleton pattern
    private FileManager(Context context) {
        sharedPreferences = context.getSharedPreferences("UserData", Context.MODE_PRIVATE);
    }

    // Public method to get the singleton instance
    public static synchronized FileManager getInstance(Context context) {
        if (instance == null) {
            instance = new FileManager(context.getApplicationContext());
        }
        return instance;
    }

    // Methods to set various types of data
    public void set(String name, String value) {
        sharedPreferences.edit().putString(name, value).apply();
    }

    public void set(String name, boolean value) {
        sharedPreferences.edit().putBoolean(name, value).apply();
    }

    public void set(String name, Set<String> value) {
        sharedPreferences.edit().putStringSet(name, value).apply();
    }

    public void set(String name, int value) {
        sharedPreferences.edit().putInt(name, value).apply();
    }

    public void set(String name, float value) {
        sharedPreferences.edit().putFloat(name, value).apply();
    }

    public void set(String name, long value) {
        sharedPreferences.edit().putLong(name, value).apply();
    }

    public void setDouble(String name, double value) {
        sharedPreferences.edit().putLong(name, Double.doubleToRawLongBits(value)).apply();
    }

    // Methods to get various types of data
    public String getString(String name) {
        return sharedPreferences.getString(name, "");
    }

    public String getString(String name, String defaultValue) {
        return sharedPreferences.getString(name, defaultValue);
    }

    public Set<String> getStringSet(String name, Set<String> def) {
        return sharedPreferences.getStringSet(name, def);
    }

    public boolean getBoolean(String name) {
        return sharedPreferences.getBoolean(name, false);
    }

    public boolean getBoolean(String name, boolean defaultValue) {
        return sharedPreferences.getBoolean(name, defaultValue);
    }

    public int getInt(String name) {
        return sharedPreferences.getInt(name, 0);
    }

    public float getFloat(String name) {
        return sharedPreferences.getFloat(name, 0f);
    }

    public long getLong(String name) {
        return sharedPreferences.getLong(name, 0L);
    }

    public double getDouble(String name) {
        return Double.longBitsToDouble(sharedPreferences.getLong(name, 0));
    }

    // Methods for handling logs
    public void resetLog() {
        sharedPreferences.edit().putString("APP_LOG", "").apply();
    }

    public void addLog(String log) {
        sharedPreferences.edit().putString("APP_LOG", log).apply();
    }
}
