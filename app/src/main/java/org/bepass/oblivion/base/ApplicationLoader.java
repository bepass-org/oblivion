package org.bepass.oblivion.base;

import android.app.Application;
import android.content.Context;

import androidx.appcompat.app.AppCompatDelegate;
import com.google.android.material.color.DynamicColors;

import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.utils.ThemeHelper;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Date;

/**
 * ApplicationLoader is a custom Application class that extends the Android Application class.
 * It is designed to provide a centralized context reference throughout the application.
 */
public class ApplicationLoader extends Application {

    // Tag for logging purposes
    private static final String TAG = "ApplicationLoader";

    /**
     * This method is called when the application is starting, before any activity, service, or receiver objects (excluding content providers) have been created.
     *
     * @see android.app.Application#onCreate()
     */
    @Override
    public void onCreate() {
        super.onCreate();
        FileManager.initialize(this); // Initialize FileManager with Application context
        ThemeHelper.getInstance().init();
        ThemeHelper.getInstance().applyTheme();
        // Enable Material 3 Dynamic Color on supported devices (Android 12+)
        DynamicColors.applyToActivitiesIfAvailable(this);

        // Persist uncaught crashes to logs.txt for in-app viewing
        final Thread.UncaughtExceptionHandler previous = Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler((thread, throwable) -> {
            try {
                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                pw.println("\n=== CRASH " + new Date() + " ===");
                throwable.printStackTrace(pw);
                pw.flush();
                byte[] bytes = sw.toString().getBytes();
                try (FileOutputStream fos = openFileOutput("logs.txt", Context.MODE_APPEND)) {
                    fos.write(bytes);
                }
            } catch (Exception ignored) {}
            if (previous != null) previous.uncaughtException(thread, throwable);
        });
    }
}