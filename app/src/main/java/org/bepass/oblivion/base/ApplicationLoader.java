package org.bepass.oblivion.base;

import android.app.Application;

import org.bepass.oblivion.config.AppConfigManager;
import org.bepass.oblivion.utils.ThemeHelper;

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
        AppConfigManager.init(this);
        ThemeHelper.getInstance().init();
        ThemeHelper.getInstance().applyTheme();
    }
}