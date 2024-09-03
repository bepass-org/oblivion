package org.bepass.oblivion.ui;

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

import org.bepass.oblivion.R;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.config.AppConfigManager;
import org.bepass.oblivion.databinding.ActivityMainBinding;
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.service.OblivionVpnService;
import org.bepass.oblivion.utils.LocaleHandler;
import org.bepass.oblivion.utils.NetworkUtils;
import org.bepass.oblivion.utils.PublicIPUtils;
import org.bepass.oblivion.utils.ThemeHelper;

import java.util.Locale;

public class MainActivity extends StateAwareBaseActivity<ActivityMainBinding> {
    private long backPressedTime;
    private Toast backToast;
    private LocaleHandler localeHandler;
    private ActivityResultLauncher<Intent> vpnPermissionLauncher;

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
        if (enableVpn) {
            Intent vpnIntent = OblivionVpnService.prepare(this);
            if (vpnIntent != null) {
                vpnPermissionLauncher.launch(vpnIntent);
            } else {
                OblivionVpnService.startVpnService(this);
            }
            NetworkUtils.monitorInternetConnection(lastKnownConnectionState, this);
        } else {
            OblivionVpnService.stopVpnService(this);
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
                case DISCONNECTING:
                    updateUIForDisconnectingState();
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
        if (AppConfigManager.getSettingProxyMode()) {
            if (AppConfigManager.getSettingLan()) {
                String lanIP;
                try {
                    lanIP = NetworkUtils.getLocalIpAddress(this);
                    binding.stateText.setText(String.format(Locale.getDefault(), "%s\n socks5 over LAN on\n %s:%s", getString(R.string.connected), lanIP, AppConfigManager.getSettingPort().getValue()));
                } catch (Exception e) {
                    binding.stateText.setText(String.format(Locale.getDefault(), "%s\n socks5 over LAN on\n 0.0.0.0:%s", getString(R.string.connected), AppConfigManager.getSettingPort().getValue()));
                }
            } else {
                binding.stateText.setText(String.format(Locale.getDefault(), "%s\nsocks5 on 127.0.0.1:%s", getString(R.string.connected), AppConfigManager.getSettingPort().getValue()));
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

    private void updateUIForDisconnectingState() {
        binding.stateText.setText(R.string.disconnecting);
        binding.publicIP.setVisibility(View.GONE);
        binding.ipProgressBar.setVisibility(View.VISIBLE);
        binding.switchButton.setChecked(false, false);
        binding.switchButton.setEnabled(true);
    }
}