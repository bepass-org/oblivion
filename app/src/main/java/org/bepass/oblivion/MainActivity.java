package org.bepass.oblivion;

import android.content.Intent;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.airbnb.lottie.LottieAnimationView;
import com.airbnb.lottie.LottieProperty;
import com.airbnb.lottie.model.KeyPath;
import com.hluhovskyi.camerabutton.CameraButton;
import com.yoosef.oblivion.R;

public class MainActivity extends AppCompatActivity {

    // 1 Wait For Connect
    // 2 Connecting
    // 3 Connected
    int connectionState = 1;

    // Views
    ImageView infoIcon, bugIcon, settingsIcon;
    CameraButton switchButton;
    LottieAnimationView switchAnimation;
    TextView stateText;

    FileManager fileManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        init();
        firstValueInit();

        switchButton.setOnStateChangeListener(state -> {
            if (state == CameraButton.State.START_EXPANDING || state == CameraButton.State.START_COLLAPSING) {
                if (connectionState == 1) {
                    // From NoAction to Connecting
                    stateText.setText("در حال اتصال");
                    changeLottieAnimationColorFilterTo(0);
                    switchAnimation.playAnimation();
                    connectionState = 2;
                    

                    // TODO handle connecting Logic here and On Connected, Call connected() method

                } else if (connectionState == 2) {
                    // From Connecting to Disconnecting
                    stateText.setText("متصل نیستید");
                    changeLottieAnimationColorFilterTo(Color.WHITE);
                    connectionState = 1;

                    // TODO handle DisConnecting Logic here

                } else if (connectionState == 3) {
                    // From Connected to Disconnecting
                    stateText.setText("متصل نیستید");
                    changeLottieAnimationColorFilterTo(Color.WHITE);
                    connectionState = 1;

                    // TODO handle DisConnecting Logic here
                }
            }
        });


    }

    private void connected() {
        stateText.setText("اتصال برقرار شد");
        switchButton.cancel();
        connectionState = 3;
    }

    private void firstValueInit() {
        if (fileManager.getBoolean("isFirstValueInit")) return;

        fileManager.set("USERSETTING_endpoint", "127.0.0.1");
        fileManager.set("USERSETTING_port", "8086");

        fileManager.set("USERSETTING_goal", false);
        fileManager.set("USERSETTING_psiphon", false);
        fileManager.set("USERSETTING_lan", false);
        fileManager.set("isFirstValueInit", true);
    }

    private void init() {
        fileManager = new FileManager(getApplicationContext());

        infoIcon = findViewById(R.id.info_icon);
        bugIcon = findViewById(R.id.bug_icon);
        settingsIcon = findViewById(R.id.setting_icon);

        switchButton = findViewById(R.id.switch_button);
        switchAnimation = findViewById(R.id.animation);
        stateText = findViewById(R.id.state_text);

        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, BugActivity.class)));
        settingsIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
    }

    private void changeLottieAnimationColorFilterTo(int color) {
        switchAnimation.setFrame(1);
        switchAnimation.cancelAnimation();

        switchAnimation.addValueCallback(
                new KeyPath("**"),
                LottieProperty.COLOR_FILTER,
                frameInfo -> (color == 0) ? null : new PorterDuffColorFilter(color, PorterDuff.Mode.SRC_ATOP)
        );
    }

}