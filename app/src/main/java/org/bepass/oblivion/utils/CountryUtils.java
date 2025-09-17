package org.bepass.oblivion.utils;

import android.content.Context;
import android.content.res.Resources;

import org.bepass.oblivion.R;

import java.util.Locale;

import kotlin.Triple;

public class CountryUtils {

    public static Triple<String, String, Integer> getCountryCode(Context context, String name) {
        Resources resources = context.getResources();

        // Retrieve the list of country names in the current locale and the English names
        String[] translatedNames = resources.getStringArray(R.array.countries);
        String[] englishNames = resources.getStringArray(R.array.englishCountries);
        // First, check if the incoming name is in English and find the index directly
        for (int i = 0; i < englishNames.length; i++) {
            if (englishNames[i].equalsIgnoreCase(name)) {
                // Return the corresponding English name, the original name, and the index
                String countryCode = getCoCo(name);
                return new Triple<>(countryCode, englishNames[i], i);
            }
        }

        // If not found in English, translate the incoming country name to English
        Triple<String, String, Integer> countryCodeAndName = translateToEnglish(name, translatedNames, englishNames);

        // Get the ISO country code using the translated English name
        String countryCode = getCoCo(countryCodeAndName.component1());

        // Return the triple of country code, full country name, and index
        return new Triple<>(countryCode, countryCodeAndName.component2(), countryCodeAndName.component3());
    }
    
    public static String localeToFlagEmoji(String locale) {
        // Convert the country code to the flag emoji
        StringBuilder flagEmoji = new StringBuilder();
        for (char character : locale.toCharArray()) {
            // Convert each character to the corresponding regional indicator symbol
            flagEmoji.append(Character.toChars(character + 127397));
        }

        return flagEmoji.toString();
    }

    private static Triple<String, String, Integer> translateToEnglish(String name, String[] translatedNames, String[] englishNames) {
        for (int i = 0; i < translatedNames.length; i++) {
            if (translatedNames[i].equalsIgnoreCase(name)) {
                // Return the corresponding English name, the original translated name, and the index
                return new Triple<>(englishNames[i], translatedNames[i], i);
            }
        }

        // If translation not found, return the original name
        return new Triple<>(name, name, 0);
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
}