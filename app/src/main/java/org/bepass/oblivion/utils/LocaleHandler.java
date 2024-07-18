package org.bepass.oblivion.utils;

import android.app.AlertDialog;
import android.content.Context;

import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.os.LocaleListCompat;

import com.github.erfansn.localeconfigx.LocaleConfigXKt;

import org.bepass.oblivion.R;

import java.util.Locale;
import java.util.Objects;

public class LocaleHandler {
    private final Context context;
    private final LocaleListCompat configuredLocales;

    public LocaleHandler(Context context) {
        this.context = context;
        configuredLocales = LocaleConfigXKt.getConfiguredLocales(context);
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
