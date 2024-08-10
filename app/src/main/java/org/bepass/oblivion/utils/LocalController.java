package org.bepass.oblivion.utils;

//import android.graphics.Typeface;
//import android.graphics.drawable.Drawable;
//import android.os.Build;
//
//import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;

import org.bepass.oblivion.base.ApplicationLoader;

public class LocalController {

    //    public static String getString(int resourceId) {
    //        return ApplicationLoader.getAppCtx().getResources().getString(resourceId);
    //    }
    //
    //
    //    @RequiresApi(api = Build.VERSION_CODES.O)
    //    public static Typeface getFont(int resourceId) {
    //        return ApplicationLoader.getAppCtx().getResources().getFont(resourceId);
    //    }
    //
    //    public static Typeface getFont(String fontName) {
    //        try {
    //            return Typeface.createFromAsset(ApplicationLoader.getAppCtx().getAssets(), "fonts/" + fontName + ".ttf");
    //            // Use the typeface as needed
    //        } catch (Exception e) {
    //            e.printStackTrace();
    //            return null;
    //            // Handle the exception, log or display an error message
    //        }
    //    }
    //
    //    private static int getResourceIdByName(String name, String type) {
    //        return ApplicationLoader.getAppCtx().getResources().getIdentifier(
    //                name,
    //                type,
    //                ApplicationLoader.getAppCtx().getPackageName()
    //        );
    //    }


    public static int getColor(int resource) {
        return ContextCompat.getColor(ApplicationLoader.getAppCtx(), resource);
    }

    //    public static float getDimen(int resource) {
    //        return ApplicationLoader.getAppCtx().getResources().getDimension(resource);
    //    }
    //
    //
    //    public static float getDimensionPixelSize(int resource) {
    //        return ApplicationLoader.getAppCtx().getResources().getDimensionPixelSize(resource);
    //    }
    //
    //    public static Drawable getDrawable(int resource) {
    //        return ContextCompat.getDrawable(ApplicationLoader.getAppCtx(), resource);
    //    }

}