package org.bepass.oblivion;

import java.util.Locale;

public class CountryUtils {

    public static String getCountryCode(String name) {
        for (String code : Locale.getISOCountries()) {
            Locale locale = new Locale("", code);
            if (locale.getDisplayCountry().equalsIgnoreCase(name)) {
                return code;
            }
        }

        return "";
    }

    public static String getCountryName(String code) {
        Locale locale = new Locale("", code);
        return locale.getDisplayCountry();
    }

}
