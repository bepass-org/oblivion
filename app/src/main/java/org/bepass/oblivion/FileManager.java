package org.bepass.oblivion;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.Set;

/**
 * This class provides a singleton instance for managing user data within the application.
 * It utilizes SharedPreferences to store and retrieve various data types securely.
 */
public class FileManager {
    private static FileManager instance;
    private final SharedPreferences sharedPreferences;

    /**
     * Private constructor to enforce singleton pattern.
     *
     * @param context The application context used to access SharedPreferences.
     */
    private FileManager(Context context) {
        sharedPreferences = context.getSharedPreferences("UserData", Context.MODE_PRIVATE);
    }

    /**
     * Public method to retrieve the singleton instance of FileManager.
     * This ensures only one instance exists throughout the application.
     *
     * @param context The application context required for SharedPreferences.
     * @return The singleton instance of FileManager.
     */
    public static synchronized FileManager getInstance(Context context) {
        if (instance == null) {
            instance = new FileManager(context.getApplicationContext());
        }
        return instance;
    }

    // ===========================================================================
    // Methods for setting various data types

    /**
     * Stores a String value associated with a key in SharedPreferences.
     *
     * @param name  The key to identify the data.
     * @param value The String value to be stored.
     */
    public void set(String name, String value) {
        sharedPreferences.edit().putString(name, value).apply();
    }

    /**
     * Stores a boolean value associated with a key in SharedPreferences.
     *
     * @param name  The key to identify the data.
     * @param value The boolean value to be stored.
     */
    public void set(String name, boolean value) {
        sharedPreferences.edit().putBoolean(name, value).apply();
    }

    /**
     * Stores a Set of Strings associated with a key in SharedPreferences.
     *
     * @param name  The key to identify the data.
     * @param value The Set of Strings to be stored.
     */
    public void set(String name, Set<String> value) {
        sharedPreferences.edit().putStringSet(name, value).apply();
    }

    /**
     * Stores an integer value associated with a key in SharedPreferences.
     *
     * @param name  The key to identify the data.
     * @param value The integer value to be stored.
     */
    public void set(String name, int value) {
        sharedPreferences.edit().putInt(name, value).apply();
    }

    /**
     * Stores a float value associated with a key in SharedPreferences.
     *
     * @param name  The key to identify the data.
     * @param value The float value to be stored.
     */
    public void set(String name, float value) {
        sharedPreferences.edit().putFloat(name, value).apply();
    }

    /**
     * Stores a long value associated with a key in SharedPreferences.
     *
     * @param name  The key to identify the data.
     * @param value The long value to be stored.
     */
    public void set(String name, long value) {
        sharedPreferences.edit().putLong(name, value).apply();
    }

    /**
     * Stores a double value associated with a key in SharedPreferences.
     * Double values are converted to longs for storage due to limitations.
     *
     * @param name  The key to identify the data.
     * @param value The double value to be stored.
     */
    public void setDouble(String name, double value) {
        sharedPreferences.edit().putLong(name, Double.doubleToRawLongBits(value)).apply();
    }

    /**
     * Retrieves a String value associated with a key from SharedPreferences.
     * If the key doesn't exist, an empty string is returned.
     *
     * @param name The key to identify the data.
     * @return The String value associated with the key,
     * * @return "" (empty string) if the key doesn't exist.
     */
    public String getString(String name) {
        return sharedPreferences.getString(name, "");
    }

    /**
     * Retrieves a String value associated with a key from SharedPreferences.
     * If the key doesn't exist, the provided default value is returned.
     *
     * @param name        The key to identify the data.
     * @param defaultValue The default value to return if the key doesn't exist.
     * @return The String value associated with the key, or the default value if not found.
     */
    public String getString(String name, String defaultValue) {
        return sharedPreferences.getString(name, defaultValue);
    }

    /**
     * Retrieves a Set of Strings associated with a key from SharedPreferences.
     * If the key doesn't exist, the provided default set is returned.
     *
     * @param name  The key to identify the data.
     * @param def    The default Set of Strings to return if the key doesn't exist.
     * @return The Set of Strings associated with the key, or the default set if not found.
     */
    public Set<String> getStringSet(String name, Set<String> def) {
        return sharedPreferences.getStringSet(name, def);
    }

    /**
     * Retrieves a boolean value associated with a key from SharedPreferences.
     * If the key doesn't exist, false is returned.
     *
     * @param name The key to identify the data.
     * @return The boolean value associated with the key, or false if not found.
     */
    public boolean getBoolean(String name) {
        return sharedPreferences.getBoolean(name, false);
    }

    /**
     * Retrieves a boolean value associated with a key from SharedPreferences.
     * If the key doesn't exist, the provided default value is returned.
     *
     * @param name        The key to identify the data.
     * @param defaultValue The default boolean value to return if the key doesn't exist.
     * @return The boolean value associated with the key, or the default value if not found.
     */
    public boolean getBoolean(String name, boolean defaultValue) {
        return sharedPreferences.getBoolean(name, defaultValue);
    }

    /**
     * Retrieves an integer value associated with a key from SharedPreferences.
     * If the key doesn't exist, 0 is returned.
     *
     * @param name The key to identify the data.
     * @return The integer value associated with the key, or 0 if not found.
     */
    public int getInt(String name) {
        return sharedPreferences.getInt(name, 0);
    }

    /**
     * Retrieves a float value associated with a key from SharedPreferences.
     * If the key doesn't exist, 0.0f is returned.
     *
     * @param name The key to identify the data.
     * @return The float value associated with the key, or 0.0f if not found.
     */
    public float getFloat(String name) {
        return sharedPreferences.getFloat(name, 0f);
    }

    /**
     * Retrieves a long value associated with a key from SharedPreferences.
     * If the key doesn't exist, 0L is returned.
     *
     * @param name The key to identify the data.
     * @return The long value associated with the key, or 0L if not found.
     */
    public long getLong(String name) {
        return sharedPreferences.getLong(name, 0L);
    }

    /**
     * Retrieves a double value associated with a key from SharedPreferences.
     * Since doubles are stored as longs, the retrieved long is converted back to a double.
     * If the key doesn't exist, 0.0 is returned.
     *
     * @param name The key to identify the data.
     * @return The double value associated with the key, or 0.0 if not found.
     */
    public double getDouble(String name) {
        return Double.longBitsToDouble(sharedPreferences.getLong(name, 0));
    }

    // ===========================================================================
    // Methods for handling logs (optional, based on your needs)

    /**
     * Resets the log stored in SharedPreferences under the key "APP_LOG".
     * This removes any existing log message and sets it to an empty string.
     */
    public void resetLog() {
        sharedPreferences.edit().putString("APP_LOG", "").apply();
    }

    /**
     * Adds a new log message to SharedPreferences under the key "APP_LOG".
     * The existing log message (if any) will be overwritten.
     *
     * @param log The String message to be stored as the application log.
     */
    public void addLog(String log) {
        sharedPreferences.edit().putString("APP_LOG", log).apply();
    }
}
