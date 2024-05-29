package org.bepass.oblivion;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;

import androidx.appcompat.app.AppCompatActivity;

@SuppressLint("CustomSplashScreen")
public class SplashScreenActivity extends AppCompatActivity implements View.OnClickListener {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Initialize the LocaleHandler and set the locale
        LocaleHandler localeHandler = new LocaleHandler(this);
        setContentView(R.layout.activity_splash_screen);
        final int SHORT_SPLASH_DISPLAY_LENGTH = 1000; // 1 second
        findViewById(R.id.splashScreen).setOnClickListener(this);
        new Handler().postDelayed(() -> {
            // Create an Intent that will start the Main Activity.
            Intent mainIntent = new Intent(SplashScreenActivity.this, MainActivity.class);
            SplashScreenActivity.this.startActivity(mainIntent);
            SplashScreenActivity.this.finish();
        }, SHORT_SPLASH_DISPLAY_LENGTH);
    }

    @Override
    public void onClick(View v) {
        // If the user clicks on the splash screen, move to the MainActivity immediately
        Intent mainIntent = new Intent(SplashScreenActivity.this, MainActivity.class);
        SplashScreenActivity.this.startActivity(mainIntent);
        SplashScreenActivity.this.finish();
    }
}
