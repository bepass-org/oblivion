package org.bepass.oblivion.utils;

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.view.View;

import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.content.ContextCompat;

import org.bepass.oblivion.R;

public class ThemeHelper {

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

        public static Theme fromNightMode(@AppCompatDelegate.NightMode int nightMode) {
            for (Theme theme : values()) {
                if (theme.getNightMode() == nightMode) {
                    return theme;
                }
            }
            return LIGHT; // Default to LIGHT if not found
        }
    }

    private static ThemeHelper instance;
    private Theme currentTheme = Theme.LIGHT;

    private ThemeHelper() {
    }

    public static synchronized ThemeHelper getInstance() {
        if (instance == null) {
            instance = new ThemeHelper();
        }
        return instance;
    }

    public void init() {
        int themeMode = FileManager.getInt(FileManager.KeyHolder.DARK_MODE);
        currentTheme = Theme.fromNightMode(themeMode);
        applyTheme();
    }

    public void applyTheme() {
        AppCompatDelegate.setDefaultNightMode(currentTheme.getNightMode());
    }

    public void select(Theme theme) {
        currentTheme = theme;
        FileManager.set(FileManager.KeyHolder.DARK_MODE, theme.nightMode);
        applyTheme();
    }

    public Theme getCurrentTheme() {
        return currentTheme;
    }

    public Drawable getBackgroundDrawable(Context context) {
        if (currentTheme == Theme.LIGHT) {
            return ContextCompat.getDrawable(context, R.drawable.background_gradient);
        } else {
            return ContextCompat.getDrawable(context, R.color.background);
        }
    }

    public void updateActivityBackground(View view) {
        // Apply theme-based background
        Drawable backgroundDrawable = getBackgroundDrawable(view.getContext());
        if (backgroundDrawable != null) {
            view.setBackground(backgroundDrawable);
        }

        // Configure status bar based on theme
        configureStatusBar(view.getContext() instanceof Activity ? (Activity) view.getContext() : null);
    }
    @RequiresApi(api = Build.VERSION_CODES.M)
    private void configureStatusBar(Activity activity) {
        if (activity == null) return;

        activity.getWindow().setStatusBarColor(Color.TRANSPARENT);

        // Determine UI visibility flags
        int uiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;

        if (currentTheme == Theme.LIGHT) {
            // Set dark icons for light theme
            uiVisibility |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
        }

        activity.getWindow().getDecorView().setSystemUiVisibility(uiVisibility);
    }
}