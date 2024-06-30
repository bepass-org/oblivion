package org.bepass.oblivion.utils;

import android.graphics.Color;

public class ColorUtils {

    public static boolean isColorDark(int color) {
        double luminance = (0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color)) / 255;
        return luminance <= 0.5;
    }
}
