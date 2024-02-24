package org.bepass.oblivion;

import java.util.Locale;

public class CountryUtils {
    public static String getCountryCode(String name) {
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