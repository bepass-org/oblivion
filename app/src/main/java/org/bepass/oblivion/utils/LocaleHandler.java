package org.bepass.oblivion.utils;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;
import android.util.DisplayMetrics;

import java.util.Locale;

public class LocaleHandler {
    private static final String SELECTED_LANGUAGE = "SelectedLanguage";
    private static final String DEFAULT_LANGUAGE = "fa";
    private static final String[] AVAILABLE_LANGUAGES = {"fa", "en", "ru", "zh"};
    private final Context context;
    private final FileManager fileManager;

    public LocaleHandler(Context context) {
        this.context = context;
        fileManager = FileManager.getInstance(context);
        setLocale(); // Ensure the locale is set when the handler is created
    }

    public void setLocale() {
        String language = fileManager.getString(SELECTED_LANGUAGE, DEFAULT_LANGUAGE);
        setLanguage(language);
    }

    private void setLanguage(String language) {
        Locale locale = new Locale(language);
        Locale.setDefault(locale);

        Resources resources = context.getResources();
        Configuration configuration = resources.getConfiguration();
        DisplayMetrics displayMetrics = resources.getDisplayMetrics();

        configuration.setLocale(locale);

        resources.updateConfiguration(configuration, displayMetrics);
    }

    public void showLanguageSelectionDialog(Runnable onLanguageSelected) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Select Language")
                .setItems(getAvailableLanguagesNames(), new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogInterface, int which) {
                        String selectedLanguage = AVAILABLE_LANGUAGES[which];
                        saveSelectedLanguage(selectedLanguage);
                        setLanguage(selectedLanguage);
                        onLanguageSelected.run(); // Run the callback
                    }
                })
                .show();
    }


    private void saveSelectedLanguage(String language) {
        fileManager.set(SELECTED_LANGUAGE, language);
    }

    private String[] getAvailableLanguagesNames() {
        String[] languageNames = new String[AVAILABLE_LANGUAGES.length];
        for (int i = 0; i < AVAILABLE_LANGUAGES.length; i++) {
            languageNames[i] = getLanguageName(AVAILABLE_LANGUAGES[i]);
        }
        return languageNames;
    }

    private String getLanguageName(String languageCode) {
        switch (languageCode) {
            case "fa":
                return "Persian";
            case "en":
                return "English";
            case "ru":
                return "Russian";
            case "zh":
                return "Chinese";
            default:
                return languageCode;
        }
    }
    @SuppressLint("ObsoleteSdkInt")
    public void restartActivity(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            ((Activity) context).recreate();
        } else {
            Intent intent = ((Activity) context).getIntent();
            context.startActivity(intent);
            ((Activity) context).finish();
            context.startActivity(intent);
        }
    }
}

