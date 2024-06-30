package org.bepass.oblivion.utils;

import android.content.Context;

import androidx.appcompat.app.AppCompatDelegate;

import org.bepass.oblivion.base.ApplicationLoader;
public class ThemeHelper {

    // Enum to define theme constants
    public enum Theme {
        LIGHT(AppCompatDelegate.MODE_NIGHT_NO),
        DARK(AppCompatDelegate.MODE_NIGHT_YES),
        FOLLOW_SYSTEM(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM),
        UNSPECIFIED(AppCompatDelegate.MODE_NIGHT_UNSPECIFIED),
        AUTO_BATTERY(AppCompatDelegate.MODE_NIGHT_AUTO_BATTERY);

        private final int nightMode;

        Theme(int nightMode) {
            this.nightMode = nightMode;
        }

        @AppCompatDelegate.NightMode
        public int getNightMode() {
            return nightMode;
        }

        // Get Theme by night mode value
        public static Theme fromNightMode(@AppCompatDelegate.NightMode int nightMode) {
            for (Theme theme : values()) {
                if (theme.getNightMode() == nightMode) {
                    return theme;
                }
            }
            return LIGHT; // Default to LIGHT if not found
        }
    }

    private static Theme currentTheme = Theme.LIGHT;

    /**
     * Initializes the theme based on saved preferences.
     *
     * @param context the application context
     */
    public static void init(Context context) {
        int themeMode = FileManager.getInstance(context).getInt(FileManager.KeyHolder.DARK_MODE);
        currentTheme = Theme.fromNightMode(themeMode);
        applyTheme();
    }

    /**
     * Applies the current theme.
     */
    public static void applyTheme() {
        AppCompatDelegate.setDefaultNightMode(currentTheme.getNightMode());
    }

    /**
     * Sets the selected theme and applies it.
     *
     * @param theme the theme to be applied
     */
    public static void select(Theme theme) {
        currentTheme = theme;
        applyTheme();
    }

    /**
     * Retrieves the current theme.
     *
     * @return the current theme
     */
    public static Theme getCurrentTheme() {
        return currentTheme;
    }
}