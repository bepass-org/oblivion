package org.bepass.oblivion;

import android.Manifest;
import android.app.ActivityManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.suke.widget.SwitchButton;

public class MainActivity extends AppCompatActivity {
    private ActivityResultLauncher<String> pushNotificationPermissionLauncher;
    private ActivityResultLauncher<Intent> vpnPermissionLauncher;

    private Messenger serviceMessenger;
    private boolean isBound;

    // 1 Wait For Connect
    // 2 Connecting
    // 3 Connected
    int connectionState = 1;

    // Views
    ImageView infoIcon, bugIcon, settingsIcon;
    SwitchButton switchButton;
    TextView stateText;

    FileManager fileManager;

    Boolean canShowNotification = false;

    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            serviceMessenger = new Messenger(service);
            isBound = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            serviceMessenger = null;
            isBound = false;
        }
    };

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
            if(!canShowNotification) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
                }
                return;
            }
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
                stopVpnService();
            }
        });
    }

    private void sendMessageToService() {
        if (!isBound) return;
        try {
            // Create a message for the service
            Message msg = Message.obtain(null, OblivionVpnService.MSG_PERFORM_TASK);

            // Create a Messenger for the reply from the service
            Messenger replyMessenger = new Messenger(new Handler(message -> {
                if (message.what == OblivionVpnService.MSG_TASK_COMPLETED) {
                    // Handle task completion
                    onTaskCompleted();
                }
                return true;
            }));
            msg.replyTo = replyMessenger;

            // Send the message
            serviceMessenger.send(msg);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    private void onTaskCompleted() {
        // Handle the task completion here
        Toast.makeText(this, "Task completed", Toast.LENGTH_SHORT).show();
        connected();
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
            unbindService(connection);
            isBound = false;
        }
    }

    private void connected() {
        stateText.setText("اتصال برقرار شد");
        switchButton.setChecked(true);
        connectionState = 3;
    }

    private void disconnected() {
        // From Connecting to Disconnecting
        stateText.setText("متصل نیستید");
        switchButton.setChecked(false);
        connectionState = 1;
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
        sendMessageToService();
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

        switchButton = findViewById(R.id.switch_button);
        stateText = findViewById(R.id.state_text);

        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, BugActivity.class)));
        settingsIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
    }
}