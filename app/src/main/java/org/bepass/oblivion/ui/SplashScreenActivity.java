package org.bepass.oblivion.ui;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;

import org.bepass.oblivion.R;
import org.bepass.oblivion.base.BaseActivity;
import org.bepass.oblivion.databinding.ActivitySplashScreenBinding;

/**
 * A simple splash screen activity that shows a splash screen for a short duration before navigating
 * to the main activity. This class extends {@link BaseActivity} and uses data binding.
 */
@SuppressLint("CustomSplashScreen")
public class SplashScreenActivity extends BaseActivity<ActivitySplashScreenBinding> {

    /**
     * Returns the layout resource ID for the splash screen activity.
     *
     * @return The layout resource ID.
     */
    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_splash_screen;
    }

    /**
     * Called when the activity is first created. This method sets up the splash screen and
     * schedules the transition to the main activity.
     *
     * @param savedInstanceState If the activity is being re-initialized after previously being shut down
     *                           then this Bundle contains the data it most recently supplied in onSaveInstanceState(Bundle).
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding.setHandler(new ClickHandler());
        // 1 second
        int SHORT_SPLASH_DISPLAY_LENGTH = 1000;
        new Handler().postDelayed(() -> {
            MainActivity.start(this);
            finish();
        }, SHORT_SPLASH_DISPLAY_LENGTH);
    }

    /**
     * A click handler for handling user interactions with the splash screen.
     */
    public class ClickHandler {

        /**
         * Called when the root view is pressed. This method immediately navigates to the main activity
         * and finishes the splash screen activity.
         *
         * @param view The view that was clicked.
         */
        public void OnRootPressed(View view) {
            MainActivity.start(SplashScreenActivity.this);
            finish();
        }
    }

}
