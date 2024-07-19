package org.bepass.oblivion.ui;

import static org.bepass.oblivion.service.OblivionVpnService.startVpnService;
import static org.bepass.oblivion.service.OblivionVpnService.stopVpnService;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
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
import java.util.HashSet;
import java.util.Set;

public class MainActivity extends StateAwareBaseActivity<ActivityMainBinding> {
    private long backPressedTime;
    private Toast backToast;
    private LocaleHandler localeHandler;

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
        // Initialize the LocaleHandler and set the locale
        localeHandler = new LocaleHandler(this);

        super.onCreate(savedInstanceState);
        // Update background based on current theme
        ThemeHelper.getInstance().updateActivityBackground(binding.getRoot());

        cleanOrMigrateSettings();
        setupUI();

        setupVPNConnection();
        // Request permission to create push notifications
        requestNotificationPermission();

        // Set the behaviour of the back button
        handleBackPress();
    }

    private void setupVPNConnection() {
        ActivityResultLauncher<Intent> vpnPermissionLauncher = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(), result -> {
                    if (result.getResultCode() != RESULT_OK) {
                        Toast.makeText(this, "Really!?", Toast.LENGTH_LONG).show();
                    }
                    binding.switchButton.setChecked(false);
                });

        binding.switchButton.setOnCheckedChangeListener((view, isChecked) -> {
            if (!isChecked) {
                if (!lastKnownConnectionState.isDisconnected()) {
                    stopVpnService(this);
                }
                return;
            }
            Intent vpnIntent = OblivionVpnService.prepare(this);
            if (vpnIntent != null) {
                vpnPermissionLauncher.launch(vpnIntent);
                return;
            }
            if (lastKnownConnectionState.isConnecting()) {
                stopVpnService(this);
                return;
            }
            if (lastKnownConnectionState.isDisconnected()) {
                startVpnService(this);
            }
            NetworkUtils.monitorInternetConnection(lastKnownConnectionState,this);
        });
    }

    private void handleBackPress() {
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (backPressedTime + 2000 > System.currentTimeMillis()) {
                    if (backToast != null) backToast.cancel();
                    finish();
                } else {
                    if (backToast != null)
                        backToast.cancel();
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
        binding.floatingActionButton.setOnClickListener(v -> localeHandler.showLanguageSelectionDialog(() ->
                localeHandler.restartActivity(this)));
        binding.infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        binding.bugIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, LogActivity.class)));
        binding.settingIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, SettingsActivity.class)));
        binding.switchButtonFrame.setOnClickListener(v -> binding.switchButton.toggle());
    }



    protected void cleanOrMigrateSettings() {
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

        // Check which split mode apps have been uninstalled and remove them from the list in settings
        Set<String> splitApps = fileManager.getStringSet("splitTunnelApps", new HashSet<>());
        Set<String> shouldKeep = new HashSet<>();
        final PackageManager pm = getApplicationContext().getPackageManager();
        for (String packageName : splitApps) {
            try {
                pm.getPackageInfo(packageName, PackageManager.GET_META_DATA);
            } catch (PackageManager.NameNotFoundException ignored) {
                continue;
            }
            shouldKeep.add(packageName);
        }
        fileManager.set("splitTunnelApps", shouldKeep);
    }

    @NonNull
    @Override
    public String getKey() {
        return "mainActivity";
    }

    @Override
    public void onConnectionStateChange(ConnectionState state) {
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
        binding.stateText.setText(R.string.connected);
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
