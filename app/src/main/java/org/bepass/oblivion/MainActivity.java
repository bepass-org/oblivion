package org.bepass.oblivion;

import android.Manifest;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;

import com.suke.widget.SwitchButton;
import org.bepass.oblivion.R;

public class MainActivity extends AppCompatActivity {
    private ActivityResultLauncher<String> pushNotificationPermissionLauncher;

    // 1 Wait For Connect
    // 2 Connecting
    // 3 Connected
    int connectionState = 1;

    // Views
    ImageView infoIcon, bugIcon, settingsIcon;
    SwitchButton switchButton;
    TextView stateText;

    FileManager fileManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        init();
        firstValueInit();
        switchButton.setOnCheckedChangeListener((view, isChecked) -> {
            if (isChecked) {
                // Switch is now ON
                if (connectionState == 1) {
                    // From NoAction to Connecting
                    stateText.setText("در حال اتصال...");
                    connectionState = 2;

                    // TODO handle connecting Logic here and On Connected, Call connected() method

                } else if (connectionState == 3) {
                    // From Connected to Disconnecting
                    stateText.setText("متصل نیستید");
                    connectionState = 1;

                    // TODO handle DisConnecting Logic here
                }
            } else {
                // Switch is now OFF
                if (connectionState == 2) {
                    // From Connecting to Disconnecting
                    stateText.setText("متصل نیستید");
                    connectionState = 1;

                    // TODO handle DisConnecting Logic here
                }
            }
        });
    }

    private void connected() {
        stateText.setText("اتصال برقرار شد");
        switchButton.setActivated(true);
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

    private void initPermissionLauncher() {
        pushNotificationPermissionLauncher = registerForActivityResult(
                new ActivityResultContracts.RequestPermission(),
                isGranted -> {
                    if (isGranted) {
                        Toast.makeText(this, "Permission granted", Toast.LENGTH_LONG).show();
                    } else {
                        Toast.makeText(this, "Permission denied", Toast.LENGTH_LONG).show();
                    }
                }
        );
    }

    private void init() {
        initPermissionLauncher();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
        }
        fileManager = new FileManager(getApplicationContext());

        infoIcon = findViewById(R.id.info_icon);
        bugIcon = findViewById(R.id.bug_icon);
        settingsIcon = findViewById(R.id.setting_icon);

        switchButton = findViewById(R.id.switch_button);
        stateText = findViewById(R.id.state_text);

        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, BugActivity.class)));
        settingsIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
    }
}