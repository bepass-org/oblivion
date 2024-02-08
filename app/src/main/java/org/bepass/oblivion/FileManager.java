package org.bepass.oblivion;

import android.content.Context;
import android.content.SharedPreferences;

public class FileManager {
    SharedPreferences sharedPreferences;
    SharedPreferences sharedPreferencesAppender;

    public FileManager(Context context) {
        sharedPreferences = context.getSharedPreferences("UserData", Context.MODE_PRIVATE);
        sharedPreferencesAppender = context.getSharedPreferences("UserData", Context.MODE_PRIVATE);
    }

    public void set(String name, String value) {
        this.sharedPreferences.
                edit()
                .putString(name, value)
                .apply();
    }

    public void set(String name, boolean value) {
        this.sharedPreferences
                .edit()
                .putBoolean(name, value)
                .apply();
    }

    public void set(String name, int value) {
        this.sharedPreferences
                .edit()
                .putInt(name, value)
                .apply();
    }

    public void set(String name, float value) {
        this.sharedPreferences
                .edit()
                .putFloat(name, value)
                .apply();
    }

    public void set(String name, double value) {
        this.sharedPreferences
                .edit()
                .putLong(name, Double.doubleToRawLongBits(value))
                .apply();
    }

    public void set(String name, long value) {
        this.sharedPreferences
                .edit()
                .putLong(name, value)
                .apply();
    }

    public double getDouble(String name) {
        return Double.longBitsToDouble(this.sharedPreferences.getLong(name, 0));
    }

    public long getLong(String name) {
        return this.sharedPreferences.getLong(name, 0L);
    }

    public String getString(String name) {
        return this.sharedPreferences.getString(name, "");
    }

    public Integer getInt(String name) {
        return this.sharedPreferences.getInt(name, 0);
    }

    public Boolean getBoolean(String name) {
        return this.sharedPreferences.getBoolean(name, false);
    }

    public Float getFloat(String name) {
        return this.sharedPreferences.getFloat(name, 0f);
    }

    public void resetLog() {
        this.sharedPreferences
                .edit()
                .putString("APP_LOG", "")
                .apply();
    }

    public void addLog(String log) {
        this.sharedPreferencesAppender
                .edit()
                .putString("APP_LOG", log)
                .apply();
    }

    public String getLog() {
        return getString("APP_LOG");
    }


}
