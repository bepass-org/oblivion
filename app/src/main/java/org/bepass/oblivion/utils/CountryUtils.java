package org.bepass.oblivion.utils;

import android.content.Context;
import android.content.res.Resources;
import android.util.Pair;

import org.bepass.oblivion.R;

import java.util.Locale;

public class CountryUtils {
    public static Pair<String, String> getCountryCode(Context context, String name){
        Resources resources = context.getResources();

        String[] translatedNames = resources.getStringArray(R.array.countries);
        // Change locale to English
        LocaleHelper.goEn(context);

        // Translate the incoming country name to English
        Pair<String, String> countryCodeAndName = translateToEnglish(context, name, translatedNames);

        // Get the ISO country code using the translated name
        String countryCode = getCoCo(countryCodeAndName.first);

        // Restore the original locale
        LocaleHelper.restoreLocale(context);
        // Return the pair of country code and full country name
        return new Pair<>(countryCode, countryCodeAndName.second);
    }

    private static Pair<String, String> translateToEnglish(Context context, String name, String[] translatedNames) {
        Resources resources = context.getResources();
        String[] englishNames = resources.getStringArray(R.array.englishCountries);
        for (int i = 0; i < translatedNames.length; i++) {
            if (translatedNames[i].equalsIgnoreCase(name)) {
                return new Pair<>(englishNames[i], translatedNames[i]);
            }
        }

        // If translation not found, return the original name
        return new Pair<>(name, name);
    }

    private static String getCoCo(String name) {
        for (String code : Locale.getISOCountries()) {
            Locale locale = new Locale("en", code); // Set the language to English
            if (locale.getDisplayCountry(Locale.ENGLISH).equalsIgnoreCase(name)) {
                return code;
            }
        }
        return "";
    }

    public static String getCountryName(String code) {
        Locale locale = new Locale("en", code); // Set the language to English
        return locale.getDisplayCountry(Locale.ENGLISH);
    }
}