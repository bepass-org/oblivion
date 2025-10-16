package org.bepass.oblivion.utils;

import android.app.Activity;
import android.content.res.Resources;
import android.os.Build;
import android.util.Log;
import android.view.View;
import android.view.Window;

import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

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

    /**
     * Enable edge-to-edge by letting app content draw behind system bars and
     * applying system bar insets as padding to the provided root view.
     */
    public static void enableEdgeToEdge(Activity activity, View root) {
        try {
            WindowCompat.setDecorFitsSystemWindows(activity.getWindow(), false);
            ViewCompat.setOnApplyWindowInsetsListener(root, (v, insets) -> {
                Insets sysBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
                v.setPadding(sysBars.left, sysBars.top, sysBars.right, sysBars.bottom);
                return insets;
            });
            WindowInsetsControllerCompat controller = ViewCompat.getWindowInsetsController(root);
            if (controller != null) {
                // Let the system decide light/dark icons based on background; default to auto
                controller.setAppearanceLightStatusBars(false);
                controller.setAppearanceLightNavigationBars(false);
            }
        } catch (Throwable ignored) {
        }
    }
}
