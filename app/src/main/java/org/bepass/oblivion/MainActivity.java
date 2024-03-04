package org.bepass.oblivion;

import android.Manifest;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import android.window.OnBackInvokedDispatcher;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;

import com.suke.widget.SwitchButton;

public class MainActivity extends ConnectionAwareBaseActivity {
    // Views
    ImageView infoIcon, bugIcon, settingsIcon;
    TouchAwareSwitch switchButton;
    TextView stateText, publicIP;
    ProgressBar ipProgressBar;
    FileManager fileManager;
    Boolean canShowNotification = false;
    private ActivityResultLauncher<String> pushNotificationPermissionLauncher;
    private ActivityResultLauncher<Intent> vpnPermissionLauncher;
    private long backPressedTime;
    private Toast backToast;

    private SwitchButton.OnCheckedChangeListener createSwitchCheckedChangeListener() {
        return (view, isChecked) -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !canShowNotification) {
                pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
                return;
            }

            if (!lastKnownConnectionState.isDisconnected()) {
                OblivionVpnService.stopVpnService(this);
                return;
            }

            if (isChecked) {
                // From NoAction to Connecting
                Intent vpnIntent = OblivionVpnService.prepare(this);
                if (vpnIntent != null) {
                    vpnPermissionLauncher.launch(vpnIntent);
                } else {
                    OblivionVpnService.startVpnService(this);
                }
            }

        };
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                // Custom back pressed logic here
                if (backPressedTime + 2000 > System.currentTimeMillis()) {
                    if (backToast != null) backToast.cancel();
                    finish(); // or super.handleOnBackPressed() if you want to keep default behavior alongside
                } else {
                    if (backToast != null) backToast.cancel(); // Cancel the existing toast to avoid stacking
                    backToast = Toast.makeText(MainActivity.this, "برای خروج، دوباره بازگشت را فشار دهید.", Toast.LENGTH_SHORT);
                    backToast.show();
                }
                backPressedTime = System.currentTimeMillis();
            }
        });
        init();
        firstValueInit();
        switchButton.setOnCheckedChangeListener(createSwitchCheckedChangeListener());

    }

    @NonNull
    @Override
    String getKey() {
        return "mainActivity";
    }

    @Override
    void onConnectionStateChange(ConnectionState state) {
        updateUi();
    }

    private void updateUi() {
        switch (lastKnownConnectionState) {
            case DISCONNECTED:
                disconnected();
                break;
            case CONNECTING:
                connecting();
                break;
            case CONNECTED:
                connected();
                break;
        }
    }

    private void getIPDetails() {
        ipProgressBar.setVisibility(View.VISIBLE);
        int port = Integer.parseInt(fileManager.getString("USERSETTING_port"));
        PublicIPUtils.getIPDetails(port, (details) -> {
            ipProgressBar.setVisibility(View.GONE);
            if (details.ip != null && details.flag != null){
                String ipString = details.ip  + " " + details.flag;
                publicIP.setText(ipString);
                publicIP.setVisibility(View.VISIBLE);
            }
        });
    }

    private void connected() {
        stateText.setText("اتصال برقرار شد");
        switchButton.setChecked(true, false);
        getIPDetails();
    }

    private void connecting() {
        stateText.setText("در حال اتصال...");
        publicIP.setVisibility(View.GONE);
        switchButton.setChecked(true, false);
    }

    private void disconnected() {
        stateText.setText("متصل نیستید");
        publicIP.setVisibility(View.GONE);
        switchButton.setChecked(false, false);
    }

    private void firstValueInit() {
        if (fileManager.getBoolean("isFirstValueInit")) return;

        fileManager.set("USERSETTING_endpoint", "engage.cloudflareclient.com:2408");
        fileManager.set("USERSETTING_port", "8086");

        fileManager.set("USERSETTING_gool", false);
        fileManager.set("USERSETTING_psiphon", false);
        fileManager.set("USERSETTING_lan", false);
        fileManager.set("isFirstValueInit", true);
    }

    private void initPermissionLauncher() {
        pushNotificationPermissionLauncher = registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
            if (isGranted) {
                canShowNotification = true;
            } else {
                disconnected();
                Toast.makeText(this, "Permission denied", Toast.LENGTH_LONG).show();
            }
        });
        vpnPermissionLauncher = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
            if (result.getResultCode() == RESULT_OK) {
                OblivionVpnService.startVpnService(this);
            } else {
                OblivionVpnService.stopVpnService(this);
                Toast.makeText(this, "Really!?", Toast.LENGTH_LONG).show();
            }
        });
    }

    private void init() {
        initPermissionLauncher();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
        }
        fileManager = FileManager.getInstance(getApplicationContext());

        infoIcon = findViewById(R.id.info_icon);
        bugIcon = findViewById(R.id.bug_icon);
        settingsIcon = findViewById(R.id.setting_icon);

        switchButton = findViewById(R.id.switch_button);
        stateText = findViewById(R.id.state_text);
        publicIP = findViewById(R.id.publicIP);
        ipProgressBar = (ProgressBar)findViewById(R.id.ipProgressBar);

        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, BugActivity.class)));
        settingsIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
    }
}
