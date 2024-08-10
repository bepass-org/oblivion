package org.bepass.oblivion.utils;

import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.Build;

import org.bepass.oblivion.R;

import java.util.Locale;

public class LocaleHelper {
    private static Locale originalLocale;

    public static void goEn(Context context) {
        Resources resources = context.getResources();
        Configuration configuration = resources.getConfiguration();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            originalLocale = configuration.getLocales().get(0); // Save the original locale
        }

        // Change locale to English
        configuration.setLocale(new Locale("en"));
        resources.updateConfiguration(configuration, resources.getDisplayMetrics());
    }

    public static void restoreLocale(Context context) {
        if (originalLocale != null) {
            Resources resources = context.getResources();
            Configuration configuration = resources.getConfiguration();

            // Restore the original locale
            configuration.setLocale(originalLocale);
            resources.updateConfiguration(configuration, resources.getDisplayMetrics());
        }
    }

    public static String restoreText(Context context, String text) {
        if (originalLocale != null) {
            Resources resources = context.getResources();
            // Load the English country names
            String[] englishNames = resources.getStringArray(R.array.englishCountries);
            restoreLocale(context);
            // Load the translated country names
            String[] translatedNames = resources.getStringArray(R.array.countries);

            // Find the translated name by matching the English name
            for (int i = 0; i < englishNames.length; i++) {
                if (englishNames[i].equalsIgnoreCase(text)) {
                    return translatedNames[i];
                }
            }
        }
        return text; // Return the original text if no translation is found or original locale is not set
    }
}