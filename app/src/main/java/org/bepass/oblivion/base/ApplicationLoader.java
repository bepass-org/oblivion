package org.bepass.oblivion.base;

import android.annotation.SuppressLint;
import android.app.Application;
import android.content.Context;

import androidx.appcompat.app.AppCompatDelegate;

import org.bepass.oblivion.utils.ThemeHelper;

/**
 * ApplicationLoader is a custom Application class that extends the Android Application class.
 * It is designed to provide a centralized context reference throughout the application.
 */
public class ApplicationLoader extends Application {

    // Tag for logging purposes
    private static final String TAG = "ApplicationLoader";

    // Context reference
    @SuppressLint("StaticFieldLeak")
    private static Context context;

    /**
     * This method is called when the application is starting, before any activity, service, or receiver objects (excluding content providers) have been created.
     *
     * @see android.app.Application#onCreate()
     */
    @Override
    public void onCreate() {
        super.onCreate();
        context = getApplicationContext();
        ThemeHelper.getInstance().init();
        ThemeHelper.getInstance().applyTheme();
    }

    /**
     * Returns the application context.
     *
     * @return The application context.
     */
    public static Context getAppCtx() {
        return context;
    }
}
