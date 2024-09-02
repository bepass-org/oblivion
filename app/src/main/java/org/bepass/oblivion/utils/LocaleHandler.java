package org.bepass.oblivion.utils;

import android.app.AlertDialog;
import android.content.Context;
import android.content.res.Resources;
import android.util.Log;

import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.os.LocaleListCompat;

import com.github.erfansn.localeconfigx.LocaleConfigXKt;

import org.bepass.oblivion.R;
import org.bepass.oblivion.config.AppConfigManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

public class LocaleHandler {
    private final Context context;
    private final LocaleListCompat configuredLocales;

    private static final String DEFAULT_LOCALE = "fa";
    private static final String IS_SET_DEFAULT_LOCALE = "is_set_default_locale";

    // Define a variable to hold allowed languages
    private final List<String> allowedLanguages;

    public LocaleHandler(Context context) {
        this.context = context;

        // Initialize allowedLanguages from resources
        this.allowedLanguages = Arrays.asList(context.getResources().getStringArray(R.array.allowed_languages));

        LocaleListCompat locales;
        try {
            // Attempt to get configured locales
            locales = LocaleConfigXKt.getConfiguredLocales(context);
            if (locales.isEmpty()) {
                throw new Resources.NotFoundException("No locales found");
            }
        } catch (Exception e) {
            // Log error and attempt to load all available locales from resources
            Log.e("LocaleHandler", "Failed to load locale configuration. Attempting to load all available locales.", e);
            try {
                // Retrieve all available locales from the app's resources
                String[] availableLocales = context.getResources().getAssets().getLocales();
                String[] validLocales = filterValidLocales(availableLocales);
                locales = LocaleListCompat.forLanguageTags(joinLocales(filterAllowedLocales(validLocales)));
            } catch (Exception ex) {
                // Fallback to system locales if loading from resources fails
                Log.e("LocaleHandler", "Failed to load available locales from resources. Attempting to use system locales.", ex);
                locales = LocaleListCompat.forLanguageTags(joinLocales(filterAllowedLocales(getSystemLocales())));
            }
        }

        this.configuredLocales = locales;
    }

    private String[] getSystemLocales() {
        Locale[] locales = Locale.getAvailableLocales();
        List<String> localCountries = new ArrayList<>();
        for (Locale locale : locales) {
            String languageTag = locale.toLanguageTag();
            if (!languageTag.isEmpty() && !languageTag.equals("und")) {
                localCountries.add(languageTag);
            }
        }
        return localCountries.toArray(new String[0]);
    }

    private String[] filterValidLocales(String[] locales) {
        if (locales == null) {
            return new String[0];
        }

        List<String> validLocales = new ArrayList<>();
        for (String localeTag : locales) {
            if (!localeTag.isEmpty() && !localeTag.equals("und")) {
                validLocales.add(localeTag);
            }
        }
        return validLocales.toArray(new String[0]);
    }

    private String[] filterAllowedLocales(String[] locales) {
        List<String> filteredLocales = new ArrayList<>();
        for (String localeTag : locales) {
            Locale locale = Locale.forLanguageTag(localeTag);
            if (allowedLanguages.contains(locale.getLanguage())) {
                filteredLocales.add(localeTag);
            }
        }
        return filteredLocales.toArray(new String[0]);
    }

    private String joinLocales(String[] locales) {
        StringBuilder joinedLocales = new StringBuilder();
        for (int i = 0; i < locales.length; i++) {
            joinedLocales.append(locales[i]);
            if (i < locales.length - 1) {
                joinedLocales.append(",");
            }
        }
        return joinedLocales.toString();
    }

    public void setPersianAsDefaultLocaleIfNeeds() {
        if (!AppConfigManager.getRawBoolean(IS_SET_DEFAULT_LOCALE, false)) {
            Locale persianLocale = Locale.forLanguageTag(DEFAULT_LOCALE);
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.create(persianLocale));
            AppConfigManager.setRawBoolean(IS_SET_DEFAULT_LOCALE, true);
        }
    }

    public void showLanguageSelectionDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle(R.string.select_language)
                .setItems(getAvailableLanguagesNames(), (dialogInterface, which) -> {
                    Locale selectedLocale = configuredLocales.get(which);
                    LocaleListCompat desiredLocales = LocaleListCompat.create(selectedLocale);
                    AppCompatDelegate.setApplicationLocales(desiredLocales);
                })
                .show();
    }

    private String[] getAvailableLanguagesNames() {
        String[] languageNames = new String[configuredLocales.size()];
        for (int index = 0; index < configuredLocales.size(); index++) {
            Locale locale = configuredLocales.get(index);
            languageNames[index] = locale != null ? locale.getDisplayName() : "Unknown";
        }
        return languageNames;
    }
}