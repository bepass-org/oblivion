package org.bepass.oblivion.ui;

import static org.bepass.oblivion.service.OblivionVpnService.stopVpnService;
import org.bepass.oblivion.service.OblivionVpnService;
import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.utils.LocaleHandler;
import org.bepass.oblivion.utils.PublicIPUtils;
import org.bepass.oblivion.R;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.databinding.ActivityMainBinding;
import org.bepass.oblivion.utils.ThemeHelper;
import org.bepass.oblivion.utils.NetworkUtils;

import java.util.Locale;

public class MainActivity extends StateAwareBaseActivity<ActivityMainBinding> {
    private long backPressedTime;
    private Toast backToast;
    private LocaleHandler localeHandler;
    private ActivityResultLauncher<Intent> vpnPermissionLauncher;
    public static void startVpnService(Context context, Intent intent) {
        intent.putExtra("USERSETTING_proxymode", FileManager.getBoolean("USERSETTING_proxymode"));
        intent.putExtra("USERSETTING_license", FileManager.getString("USERSETTING_license"));
        intent.putExtra("USERSETTING_endpoint_type", FileManager.getInt("USERSETTING_endpoint_type"));
        intent.putExtra("USERSETTING_psiphon", FileManager.getBoolean("USERSETTING_psiphon"));
        intent.putExtra("USERSETTING_country", FileManager.getString("USERSETTING_country"));
        intent.putExtra("USERSETTING_gool", FileManager.getBoolean("USERSETTING_gool"));
        intent.putExtra("USERSETTING_endpoint", FileManager.getString("USERSETTING_endpoint"));
        intent.putExtra("USERSETTING_port", FileManager.getString("USERSETTING_port"));
        intent.putExtra("USERSETTING_lan", FileManager.getBoolean("USERSETTING_lan"));
        intent.setAction(OblivionVpnService.FLAG_VPN_START);
        ContextCompat.startForegroundService(context, intent);
    }
    public static void start(Context context) {
        Intent starter = new Intent(context, MainActivity.class);
        starter.putExtra("origin", context.getClass().getSimpleName());
        context.startActivity(starter);
    }

    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_main;
    }

    @Override
    protected int getStatusBarColor() {
        return R.color.status_bar_color;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        localeHandler = new LocaleHandler(this);
        ThemeHelper.getInstance().updateActivityBackground(binding.getRoot());
        FileManager.cleanOrMigrateSettings(this);
        setupUI();
        setupVPNConnection();
        requestNotificationPermission();
        handleBackPress();
    }

    private void setupVPNConnection() {
        vpnPermissionLauncher = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(), result -> {
                    if (result.getResultCode() == RESULT_OK) {
                        handleVpnSwitch(binding.switchButton.isChecked());
                    } else {
                        Toast.makeText(this, "Permission required to start VPN", Toast.LENGTH_LONG).show();
                        binding.switchButton.setChecked(false);
                    }
                });

        binding.switchButton.setOnCheckedChangeListener((view, isChecked) -> handleVpnSwitch(isChecked));
    }

    private void handleVpnSwitch(boolean enableVpn) {
        Log.d("83", FileManager.getString("USERSETTING_country"));
        FileManager.initialize(this);

        if (enableVpn) {
            if (lastKnownConnectionState.isDisconnected()) {
                Intent vpnIntent = OblivionVpnService.prepare(this);
                if (vpnIntent != null) {
                    vpnPermissionLauncher.launch(vpnIntent);
                } else {
                    vpnIntent = new Intent(this, OblivionVpnService.class);
                    startVpnService(this, vpnIntent);
                }
                NetworkUtils.monitorInternetConnection(lastKnownConnectionState, this);
            } else if (lastKnownConnectionState.isConnecting()) {
                stopVpnService(this);
            }
        } else {
            if (!lastKnownConnectionState.isDisconnected()) {
                stopVpnService(this);
            }
        }

        refreshUI(); // Force refresh of the UI after VPN state changes
    }
    private void refreshUI() {
        // This will force a refresh of the UI based on the current data bindings
        binding.invalidateAll();
        binding.executePendingBindings();
    }

    private void handleBackPress() {
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (backPressedTime + 2000 > System.currentTimeMillis()) {
                    if (backToast != null) backToast.cancel();
                    finish();
                } else {
                    if (backToast != null) backToast.cancel();
                    backToast = Toast.makeText(MainActivity.this, "برای خروج، دوباره بازگشت را فشار دهید.", Toast.LENGTH_SHORT);
                    backToast.show();
                }
                backPressedTime = System.currentTimeMillis();
            }
        });
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityResultLauncher<String> pushNotificationPermissionLauncher = registerForActivityResult(
                    new ActivityResultContracts.RequestPermission(), isGranted -> {
                        if (!isGranted) {
                            Toast.makeText(this, "Permission denied", Toast.LENGTH_LONG).show();
                        }
                    });
            pushNotificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
        }
    }

    private void setupUI() {
        binding.floatingActionButton.setOnClickListener(v -> localeHandler.showLanguageSelectionDialog());
        binding.infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        binding.bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, LogActivity.class)));
        binding.settingIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
        binding.switchButtonFrame.setOnClickListener(v -> binding.switchButton.toggle());
    }

    @NonNull
    @Override
    public String getKey() {
        return "mainActivity";
    }

    @Override
    protected void onResume() {
        super.onResume();
        observeConnectionStatus();
    }

    @Override
    public void onConnectionStateChange(ConnectionState state) {
        runOnUiThread(() -> {
            Log.d("MainActivity", "Connection state changed to: " + state);
            switch (state) {
                case DISCONNECTED:
                    updateUIForDisconnectedState();
                    break;
                case CONNECTING:
                    updateUIForConnectingState();
                    break;
                case CONNECTED:
                    updateUIForConnectedState();
                    break;
            }
            refreshUI(); // Refresh UI whenever the connection state changes
        });
    }

    private void updateUIForDisconnectedState() {
        binding.publicIP.setVisibility(View.GONE);
        binding.stateText.setText(R.string.notConnected);
        binding.ipProgressBar.setVisibility(View.GONE);
        binding.switchButton.setEnabled(true);
        binding.switchButton.setChecked(false, false);
    }

    private void updateUIForConnectingState() {
        binding.stateText.setText(R.string.connecting);
        binding.publicIP.setVisibility(View.GONE);
        binding.ipProgressBar.setVisibility(View.VISIBLE);
        binding.switchButton.setChecked(true, false);
        binding.switchButton.setEnabled(true);
    }

    private void updateUIForConnectedState() {
        binding.switchButton.setEnabled(true);
        if (FileManager.getBoolean("USERSETTING_proxymode")) {
            if (FileManager.getBoolean("USERSETTING_lan")) {
                String lanIP;
                try {
                    lanIP = NetworkUtils.getLocalIpAddress(this);
                    binding.stateText.setText(String.format(Locale.getDefault(), "%s\n socks5 over LAN on\n %s:%s", getString(R.string.connected), lanIP, FileManager.getString("USERSETTING_port")));
                } catch (Exception e) {
                    binding.stateText.setText(String.format(Locale.getDefault(), "%s\n socks5 over LAN on\n 0.0.0.0:%s", getString(R.string.connected), FileManager.getString("USERSETTING_port")));
                }
            } else {
                binding.stateText.setText(String.format(Locale.getDefault(), "%s\nsocks5 on 127.0.0.1:%s", getString(R.string.connected), FileManager.getString("USERSETTING_port")));
            }
        } else {
            binding.stateText.setText(R.string.connected);
        }
        binding.switchButton.setChecked(true, false);
        binding.ipProgressBar.setVisibility(View.GONE);
        PublicIPUtils.getInstance().getIPDetails((details) -> runOnUiThread(() -> { // Ensure UI updates are done on the main thread
            if (details.ip != null) {
                String ipString = details.ip + " " + details.flag;
                binding.publicIP.setText(ipString);
                binding.publicIP.setVisibility(View.VISIBLE);
            }
        }));
    }
}