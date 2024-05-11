package org.bepass.oblivion;

import android.Manifest;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;

public class MainActivity extends StateAwareBaseActivity {
    private TouchAwareSwitch switchButton;
    private TextView stateText, publicIP;
    private ProgressBar ipProgressBar;
    private PublicIPUtils pIPUtils;
    private long backPressedTime;
    private Toast backToast;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Get the global FileManager instance
        FileManager fileManager = FileManager.getInstance(getApplicationContext());

        if (!fileManager.getBoolean("isFirstValueInit")) {
            fileManager.set("USERSETTING_endpoint", "engage.cloudflareclient.com:2408");
            fileManager.set("USERSETTING_port", "8086");
            fileManager.set("USERSETTING_gool", false);
            fileManager.set("USERSETTING_psiphon", false);
            fileManager.set("USERSETTING_lan", false);
            fileManager.set("isFirstValueInit", true);
        }

        // Get the global PublicIPUtils instance
        pIPUtils = PublicIPUtils.getInstance(getApplicationContext());

        // Set the layout of the main activity
        setContentView(R.layout.activity_main);

        // Views
        ImageView infoIcon = findViewById(R.id.info_icon);
        ImageView bugIcon = findViewById(R.id.bug_icon);
        ImageView settingsIcon = findViewById(R.id.setting_icon);

        FrameLayout switchButtonFrame = findViewById(R.id.switch_button_frame);
        switchButton = findViewById(R.id.switch_button);
        stateText = findViewById(R.id.state_text);
        publicIP = findViewById(R.id.publicIP);
        ipProgressBar = findViewById(R.id.ipProgressBar);

        // Set listeners
        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, BugActivity.class)));
        settingsIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
        switchButtonFrame.setOnClickListener(v -> switchButton.toggle());

        // Request for VPN creation
        ActivityResultLauncher<Intent> vpnPermissionLauncher = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
            if (result.getResultCode() != RESULT_OK) {
                Toast.makeText(this, "Really!?", Toast.LENGTH_LONG).show();
            }
            switchButton.setChecked(false);
        });

        // Listener for toggle switch
        switchButton.setOnCheckedChangeListener((view, isChecked) -> {
            if (!isChecked) {
                if (!lastKnownConnectionState.isDisconnected()) {
                    OblivionVpnService.stopVpnService(this);
                }
                return;
            }
            Intent vpnIntent = OblivionVpnService.prepare(this);
            if (vpnIntent != null) {
                vpnPermissionLauncher.launch(vpnIntent);
                return;
            }
            if (lastKnownConnectionState.isDisconnected()) {
                OblivionVpnService.startVpnService(this);
            }
        });

        // Request permission to create push notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityResultLauncher<String> pushNotificationPermissionLauncher = registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
                if (!isGranted) {
                    Toast.makeText(this, "Permission denied", Toast.LENGTH_LONG).show();
                }
            });
            pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
        }

        // Set the behaviour of the back button
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                // Custom back pressed logic here
                if (backPressedTime + 2000 > System.currentTimeMillis()) {
                    if (backToast != null) backToast.cancel();
                    finish(); // or super.handleOnBackPressed() if you want to keep default behavior alongside
                } else {
                    if (backToast != null)
                        backToast.cancel(); // Cancel the existing toast to avoid stacking
                    backToast = Toast.makeText(MainActivity.this, "برای خروج، دوباره بازگشت را فشار دهید.", Toast.LENGTH_SHORT);
                    backToast.show();
                }
                backPressedTime = System.currentTimeMillis();
            }
        });
    }

    @NonNull
    @Override
    String getKey() {
        return "mainActivity";
    }

    @Override
    void onConnectionStateChange(ConnectionState state) {
        switch (state) {
            case DISCONNECTED:
                publicIP.setVisibility(View.GONE);
                stateText.setText("متصل نیستید");
                ipProgressBar.setVisibility(View.GONE);
                switchButton.setEnabled(true);
                switchButton.setChecked(false, false);
                break;
            case CONNECTING:
                stateText.setText("در حال اتصال...");
                publicIP.setVisibility(View.GONE);
                ipProgressBar.setVisibility(View.VISIBLE);
                switchButton.setChecked(true, false);
                switchButton.setEnabled(false);
                break;
            case CONNECTED:
                switchButton.setEnabled(true);
                stateText.setText("اتصال برقرار شد");
                switchButton.setChecked(true, false);
                ipProgressBar.setVisibility(View.GONE);
                pIPUtils.getIPDetails((details) -> {
                    if (details.ip != null) {
                        String ipString = details.ip+ " " + details.flag;
                        publicIP.setText(ipString);
                        publicIP.setVisibility(View.VISIBLE);
                    }
                });
                break;
        }
    }
}
