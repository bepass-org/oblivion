package org.bepass.oblivion;

import android.Manifest;
import android.app.ActivityManager;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.suke.widget.SwitchButton;
import org.bepass.oblivion.R;

public class MainActivity extends AppCompatActivity {
    private ActivityResultLauncher<String> pushNotificationPermissionLauncher;
    private ActivityResultLauncher<Intent> vpnPermissionLauncher;

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
        if(isMyServiceRunning()) {
            connected();
        }
        switchButton.setOnCheckedChangeListener((view, isChecked) -> {
            if (isChecked) {
                // Switch is now ON
                if (connectionState == 1) {
                    // From NoAction to Connecting
                    stateText.setText("در حال اتصال...");
                    connectionState = 2;

                    Intent vpnIntent = OblivionVpnService.prepare(this);
                    if (vpnIntent != null) {
                        vpnPermissionLauncher.launch(vpnIntent);
                    } else {
                        startVpnService();
                    }

                } else if (connectionState == 3) {
                    disconnected();
                }
            } else {
                // Switch is now OFF
                if (connectionState == 2) {
                    disconnected();
                }
            }
        });
    }

    private void connected() {
        stateText.setText("اتصال برقرار شد");
        switchButton.setActivated(true);
        connectionState = 3;
    }

    private void disconnected() {
        // From Connecting to Disconnecting
        stateText.setText("متصل نیستید");
        connectionState = 1;
        stopVpnService();
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
        vpnPermissionLauncher = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(),
                result -> {
                    if (result.getResultCode() == RESULT_OK) {
                        startVpnService();
                    } else {
                        Toast.makeText(this, "Really!?", Toast.LENGTH_LONG).show();
                    }
                }
        );
    }

    private boolean isMyServiceRunning() {
        ActivityManager manager = (ActivityManager) getSystemService(ACTIVITY_SERVICE);
        if (manager != null) {
            for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
                if (OblivionVpnService.class.getName().equals(service.service.getClassName())) {
                    return true;
                }
            }
        }
        return false;
    }

    private void startVpnService() {
        Intent intent = new Intent(this, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_START);
        ContextCompat.startForegroundService(this, intent);
        connected();
    }

    private void stopVpnService() {
        Intent intent = new Intent(this, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_STOP);
        ContextCompat.startForegroundService(this, intent);
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