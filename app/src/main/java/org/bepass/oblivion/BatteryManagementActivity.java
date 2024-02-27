package org.bepass.oblivion;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;

public class BatteryManagementActivity extends AppCompatActivity {

    private PowerManager powerManager;
    private String packageName;
    private Button battery;
    private TextView batteryStatus;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_battery_management);
        powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
        packageName = getPackageName();
        batteryStatus = findViewById(R.id.battery_current_status);
        battery = findViewById(R.id.battery_button);
        ImageView back = findViewById(R.id.back);
        Button manual = findViewById(R.id.battery_manual);

        checkOptimizationStatus();
        manual.setOnClickListener(v -> openURL());
        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

    }

    private void checkOptimizationStatus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (powerManager.isIgnoringBatteryOptimizations(packageName)) {
                battery.setText("فعال‌سازی");
                batteryStatus.setText("غیرفعال است");
                batteryStatus.setTextColor(Color.parseColor("#29862D"));
                battery.setOnClickListener(v -> enableBatteryOptimization());
            } else {
                battery.setText("غیرفعال‌سازی");
                batteryStatus.setText("فعال است");
                batteryStatus.setTextColor(Color.parseColor("#E4AB53"));
                battery.setOnClickListener(v -> disableBatteryOptimization());
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @SuppressLint("BatteryLife")
    private void disableBatteryOptimization() {
        Intent intent = new Intent();
        String packageName = getPackageName();
        intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
        intent.setData(Uri.parse("package:" + packageName));
        batteryOptimizationLauncher.launch(intent);

    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private void enableBatteryOptimization() {
        Intent intent = new Intent();
        intent.setAction(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
        batteryOptimizationLauncher.launch(intent);
    }

    private final ActivityResultLauncher<Intent> batteryOptimizationLauncher = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(),
            result -> checkOptimizationStatus());

    protected void openURL() {
        Uri uri = Uri.parse("https://dontkillmyapp.com");
        Intent intent = new Intent(Intent.ACTION_VIEW, uri);
        startActivity(intent);
    }

}