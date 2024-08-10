package org.bepass.oblivion.utils;

import android.app.Activity;
import android.content.res.Resources;
import android.os.Build;
import android.util.Log;
import android.view.View;
import android.view.Window;

import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;

public class SystemUtils {

    @RequiresApi(api = Build.VERSION_CODES.M)
    public static void setStatusBarColor(Activity activity, int color, boolean isDark) {
        try {
            int statusBarColor = ContextCompat.getColor(activity, color);
            activity.getWindow().setStatusBarColor(statusBarColor);

            // Adjust status bar icon color based on theme
            changeStatusBarIconColor(activity, isDark);
        } catch (Resources.NotFoundException e) {
            Log.e("ThemeHelper", "Failed to find color resource for status bar", e);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private static void changeStatusBarIconColor(Activity activity, boolean isDark) {
        Window window = activity.getWindow();
        View decorView = window.getDecorView();
        int flags = decorView.getSystemUiVisibility();
        if (isDark) {
            // Make status bar icons dark (e.g., for dark background)
            flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
        } else {
            // Make status bar icons light (e.g., for light background)
            flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
        }
        decorView.setSystemUiVisibility(flags);
    }
}
