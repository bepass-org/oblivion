package org.bepass.oblivion.utils;

import android.app.AlertDialog;
import android.content.Context;
import android.util.Log;

import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.os.LocaleListCompat;

import com.github.erfansn.localeconfigx.LocaleConfigXKt;

import org.bepass.oblivion.R;

import java.util.Locale;
import java.util.Objects;

public class LocaleHandler {
    private final Context context;
    private final LocaleListCompat configuredLocales;

    private static final String DEFAULT_LOCALE = "fa";
    private static final String IS_SET_DEFAULT_LOCALE = "is_set_default_locale";

    public LocaleHandler(Context context) {
        this.context = context;

        // Safely load configured locales
        LocaleListCompat locales;
        try {
            locales = LocaleConfigXKt.getConfiguredLocales(context);
            if (locales.isEmpty()) {
                throw new Exception("Locale configuration is empty or null.");
            }
        } catch (Exception e) {
            Log.e("LocaleHandler", "Failed to load locale configuration. Falling back to default locale.", e);
            locales = LocaleListCompat.create(Locale.forLanguageTag(DEFAULT_LOCALE));
        }

        this.configuredLocales = locales;
    }

    public void setPersianAsDefaultLocaleIfNeeds() {
        if (!FileManager.getBoolean(IS_SET_DEFAULT_LOCALE)) {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.create(configuredLocales.getFirstMatch(new String[] { DEFAULT_LOCALE })));
            FileManager.set(IS_SET_DEFAULT_LOCALE, true);
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
            languageNames[index] = Objects.requireNonNull(configuredLocales.get(index)).getDisplayName();
        }
        return languageNames;
    }
}
