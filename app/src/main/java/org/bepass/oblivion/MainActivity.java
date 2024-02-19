package org.bepass.oblivion;

import android.Manifest;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Messenger;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.FrameLayout;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.suke.widget.SwitchButton;

public class MainActivity extends AppCompatActivity {

    private static final String ConnectionStateObserverKey = "mainActivity";
    private ActivityResultLauncher<String> pushNotificationPermissionLauncher;
    private ActivityResultLauncher<Intent> vpnPermissionLauncher;

    private Messenger serviceMessenger;
    private boolean isBound;


    // Views
    ImageView infoIcon, bugIcon, settingsIcon;
    TouchAwareSwitch switchButton;
    TextView stateText;

    FileManager fileManager;

    Boolean canShowNotification = false;

    private ConnectionState lastKnownConnectionState = ConnectionState.DISCONNECTED;

    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            serviceMessenger = new Messenger(service);
            isBound = true;
            observeConnectionStatus();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            serviceMessenger = null;
            isBound = false;
        }
    };


    private SwitchButton.OnCheckedChangeListener createSwitchCheckedChangeListener() {
        return (view, isChecked) -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !canShowNotification) {
                pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
                return;
            }

            if (lastKnownConnectionState == ConnectionState.DISCONNECTED && isChecked) {
                // From NoAction to Connecting
                Intent vpnIntent = OblivionVpnService.prepare(this);
                if (vpnIntent != null) {
                    vpnPermissionLauncher.launch(vpnIntent);
                } else {
                    startVpnService();
                }
            } else if (lastKnownConnectionState == ConnectionState.CONNECTED || lastKnownConnectionState == ConnectionState.CONNECTING) {
                stopVpnService();
            }
        };
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        init();
        firstValueInit();
        switchButton.setOnCheckedChangeListener(createSwitchCheckedChangeListener());
    }


    private void observeConnectionStatus() {
        if (!isBound) return;
        OblivionVpnService.registerConnectionStateObserver(ConnectionStateObserverKey, serviceMessenger, new ConnectionStateChangeListener() {
            @Override
            public void onChange(ConnectionState state) {
                lastKnownConnectionState = state;
                updateUi();
            }
        });
    }

    private void unsubscribeConnectionStatus() {
        if (!isBound) return;
        OblivionVpnService.unregisterConnectionStateObserver(ConnectionStateObserverKey, serviceMessenger);
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

    @Override
    protected void onStart() {
        super.onStart();
        // Bind to the service
        bindService(new Intent(this, OblivionVpnService.class), connection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onStop() {
        super.onStop();
        // Unbind from the service
        if (isBound) {
            unsubscribeConnectionStatus();
            unbindService(connection);
            isBound = false;
        }
    }

    private void connected() {
        stateText.setText("اتصال برقرار شد");
        switchButton.setChecked(true, false);
    }

    private void connecting() {
        stateText.setText("در حال اتصال...");
        switchButton.setChecked(true, false);
    }

    private void disconnected() {
        stateText.setText("متصل نیستید");
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
        pushNotificationPermissionLauncher = registerForActivityResult(
                new ActivityResultContracts.RequestPermission(),
                isGranted -> {
                    if (isGranted) {
                        canShowNotification = true;
                    } else {
                        disconnected();
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
                        stopVpnService();
                        Toast.makeText(this, "Really!?", Toast.LENGTH_LONG).show();
                    }
                }
        );
    }


    private void startVpnService() {
        //Toast.makeText(getApplicationContext(), calculateArgs(), Toast.LENGTH_LONG).show();
        Intent intent = new Intent(this, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_START);
        ContextCompat.startForegroundService(this, intent);
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
        fileManager = FileManager.getInstance(getApplicationContext());

        infoIcon = findViewById(R.id.info_icon);
        bugIcon = findViewById(R.id.bug_icon);
        settingsIcon = findViewById(R.id.setting_icon);

        FrameLayout switchButtonFrame = findViewById(R.id.switch_button_frame);
        switchButton = findViewById(R.id.switch_button);
        stateText = findViewById(R.id.state_text);

        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, BugActivity.class)));
        settingsIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
        switchButtonFrame.setOnClickListener(v -> {
            switchButton.toggle();
        });
    }
}
