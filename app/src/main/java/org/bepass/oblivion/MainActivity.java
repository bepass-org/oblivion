package org.bepass.oblivion;

import static org.bepass.oblivion.OblivionVpnService.startVpnService;
import static org.bepass.oblivion.OblivionVpnService.stopVpnService;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
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

import com.google.android.material.floatingactionbutton.FloatingActionButton;

import java.util.HashSet;
import java.util.Set;

public class MainActivity extends StateAwareBaseActivity {
    private TouchAwareSwitch switchButton;
    private TextView stateText, publicIP;
    private ProgressBar ipProgressBar;
    private PublicIPUtils pIPUtils;
    private long backPressedTime;
    private Toast backToast;
    private LocaleHandler localeHandler;
    private final Handler handler = new Handler();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        cleanOrMigrateSettings();

        // Get the global PublicIPUtils instance
        pIPUtils = PublicIPUtils.getInstance(getApplicationContext());

        // Initialize the LocaleHandler and set the locale
        localeHandler = new LocaleHandler(this);

        // Set the layout of the main activity
        setContentView(R.layout.activity_main);

        // Handle language change based on floatingActionButton value
        FloatingActionButton floatingActionButton = findViewById(R.id.floatingActionButton);
        floatingActionButton.setOnClickListener(v -> localeHandler.showLanguageSelectionDialog(()->
                localeHandler.restartActivity(this)));
        // Views
        ImageView infoIcon = findViewById(R.id.info_icon);
        ImageView logIcon = findViewById(R.id.bug_icon);
        ImageView settingsIcon = findViewById(R.id.setting_icon);

        FrameLayout switchButtonFrame = findViewById(R.id.switch_button_frame);
        switchButton = findViewById(R.id.switch_button);
        stateText = findViewById(R.id.state_text);
        publicIP = findViewById(R.id.publicIP);
        ipProgressBar = findViewById(R.id.ipProgressBar);

        // Set listeners
        infoIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, InfoActivity.class)));
        logIcon.setOnClickListener(v -> startActivity(new Intent(MainActivity.this, LogActivity.class)));
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
                    stopVpnService(this);
                }
                return;
            }
            Intent vpnIntent = OblivionVpnService.prepare(this);
            if (vpnIntent != null) {
                vpnPermissionLauncher.launch(vpnIntent);
                return;
            }
            // Handle the case when the VPN is in the connecting state and the user clicks to abort
            if (lastKnownConnectionState.isConnecting()) {
                stopVpnService(this);
                return;
            }
            // Start the VPN service if it's disconnected
            if (lastKnownConnectionState.isDisconnected()) {
                startVpnService(this);
            }
            // To check is Internet Connection is available
            handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if(!lastKnownConnectionState.isDisconnected()) {
                            checkInternetConnectionAndDisconnectVPN();
                            handler.postDelayed(this, 3000); // Check every 3 seconds
                        }
                    }
                }, 5000); // Start checking after 5 seconds
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

    // Check internet connectivity
    private boolean isConnectedToInternet() {
        ConnectivityManager connectivityManager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectivityManager != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Network activeNetwork = connectivityManager.getActiveNetwork();
                if (activeNetwork != null) {
                    NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork);
                    return networkCapabilities != null &&
                            (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR));
                }
            } else {
                // For API levels below 23, use the deprecated method
                NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();
                return activeNetwork != null && activeNetwork.isConnectedOrConnecting();
            }
        }
        return false;
    }

    // Periodically check internet connection and disconnect VPN if not connected
    private void checkInternetConnectionAndDisconnectVPN() {
        if (!isConnectedToInternet()) {
            stopVpnService(this);
        }
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
    String getKey() {
        return "mainActivity";
    }

    @Override
    void onConnectionStateChange(ConnectionState state) {
        switch (state) {
            case DISCONNECTED:
                publicIP.setVisibility(View.GONE);
                stateText.setText(R.string.notConnected);
                ipProgressBar.setVisibility(View.GONE);
                switchButton.setEnabled(true);
                switchButton.setChecked(false, false);
                break;
            case CONNECTING:
                stateText.setText(R.string.connecting);
                publicIP.setVisibility(View.GONE);
                ipProgressBar.setVisibility(View.VISIBLE);
                switchButton.setChecked(true, false);
                switchButton.setEnabled(true);
                break;
            case CONNECTED:
                switchButton.setEnabled(true);
                stateText.setText(R.string.connected);
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
