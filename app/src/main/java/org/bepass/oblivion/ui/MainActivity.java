package org.bepass.oblivion.ui;

import static org.bepass.oblivion.service.OblivionVpnService.startVpnService;
import static org.bepass.oblivion.service.OblivionVpnService.stopVpnService;

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

import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.utils.LocaleHandler;
import org.bepass.oblivion.service.OblivionVpnService;
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

        // Initialize the LocaleHandler and set the locale
        localeHandler = new LocaleHandler(this);
        // Update background based on current theme
        ThemeHelper.getInstance().updateActivityBackground(binding.getRoot());
        FileManager.cleanOrMigrateSettings(this); // Pass this context
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
        FileManager.initialize(this);
        if (enableVpn) {
            if (lastKnownConnectionState.isDisconnected()) {
                Intent vpnIntent = OblivionVpnService.prepare(this);
                if (vpnIntent != null) {
                    vpnPermissionLauncher.launch(vpnIntent);
                } else {
                    startVpnService(this); // Use this context
                }
                NetworkUtils.monitorInternetConnection(lastKnownConnectionState, this);
            } else if (lastKnownConnectionState.isConnecting()) {
                stopVpnService(this); // Use this context
            }
        } else {
            if (!lastKnownConnectionState.isDisconnected()) {
                stopVpnService(this); // Use this context
            }
        }
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
            binding.stateText.setText(String.format(Locale.getDefault(), "socks5 %s on 127.0.0.1:%s", getString(R.string.connected), FileManager.getString("USERSETTING_port")));
        } else {
            binding.stateText.setText(R.string.connected);
        }
        binding.switchButton.setChecked(true, false);
        binding.ipProgressBar.setVisibility(View.GONE);
        PublicIPUtils.getInstance().getIPDetails((details) -> {
            if (details.ip != null) {
                String ipString = details.ip + " " + details.flag;
                binding.publicIP.setText(ipString);
                binding.publicIP.setVisibility(View.VISIBLE);
            }
        });
    }
}