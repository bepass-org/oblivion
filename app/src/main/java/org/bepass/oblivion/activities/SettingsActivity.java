package org.bepass.oblivion.activities;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import org.bepass.oblivion.EditSheet;
import org.bepass.oblivion.FileManager;
import org.bepass.oblivion.R;
import org.bepass.oblivion.SheetsCallBack;

public class SettingsActivity extends AppCompatActivity {

    FileManager fileManager;
    ImageView back;

    LinearLayout endpointLayout, portLayout, lanLayout, psiphonLayout, countryLayout, licenseLayout, goolLayout,splitTunnelLayout;

    TextView endpoint, port, country, license;
    CheckBox psiphon, lan, gool;

    private CheckBox.OnCheckedChangeListener psiphonListener;
    private CheckBox.OnCheckedChangeListener goolListener;

    private void setCheckBoxWithoutTriggeringListener(CheckBox checkBox, boolean isChecked, CheckBox.OnCheckedChangeListener listener) {
        checkBox.setOnCheckedChangeListener(null); // Temporarily detach the listener
        checkBox.setChecked(isChecked); // Set the checked state
        checkBox.setOnCheckedChangeListener(listener); // Reattach the listener
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        init();

        SheetsCallBack sheetsCallBack = this::settingBasicValuesFromSPF;
        // Listen to Changes
        endpointLayout.setOnClickListener(v -> (new EditSheet(this, "اندپوینت", "endpoint", sheetsCallBack)).start());
        portLayout.setOnClickListener(v -> (new EditSheet(this, "پورت", "port", sheetsCallBack)).start());
        countryLayout.setOnClickListener(v -> (new EditSheet(this, "کشور", "country", sheetsCallBack)).start());
        licenseLayout.setOnClickListener(v -> (new EditSheet(this, "لایسنس", "license", sheetsCallBack)).start());

        splitTunnelLayout.setOnClickListener(v -> startActivity(new Intent(this, SplitTunnelActivity.class)));

        // Set Current Values
        settingBasicValuesFromSPF();

        goolLayout.setOnClickListener(v -> gool.setChecked(!gool.isChecked()));
        lanLayout.setOnClickListener(v -> lan.setChecked(!lan.isChecked()));
        psiphonLayout.setOnClickListener(v -> psiphon.setChecked(!psiphon.isChecked()));

        lan.setOnCheckedChangeListener((buttonView, isChecked) -> fileManager.set("USERSETTING_lan", isChecked));
        // Initialize the listeners
        psiphonListener = (buttonView, isChecked) -> {
            fileManager.set("USERSETTING_psiphon", isChecked);
            if (isChecked && gool.isChecked()) {
                setCheckBoxWithoutTriggeringListener(gool, false, goolListener);
                fileManager.set("USERSETTING_gool", false);
            }
            countryLayout.setAlpha(isChecked ? 1f : 0.2f);
            countryLayout.setClickable(isChecked);
        };

        goolListener = (buttonView, isChecked) -> {
            fileManager.set("USERSETTING_gool", isChecked);
            if (isChecked && psiphon.isChecked()) {
                setCheckBoxWithoutTriggeringListener(psiphon, false, psiphonListener);
                fileManager.set("USERSETTING_psiphon", false);
                countryLayout.setAlpha(0.2f);
                countryLayout.setClickable(false);
            }
        };

        // Set the listeners to the checkboxes
        psiphon.setOnCheckedChangeListener(psiphonListener);
        gool.setOnCheckedChangeListener(goolListener);
    }

    private void settingBasicValuesFromSPF() {
        endpoint.setText(fileManager.getString("USERSETTING_endpoint"));
        port.setText(fileManager.getString("USERSETTING_port"));
        country.setText(fileManager.getString("USERSETTING_country"));
        license.setText(fileManager.getString("USERSETTING_license"));

        psiphon.setChecked(fileManager.getBoolean("USERSETTING_psiphon"));
        lan.setChecked(fileManager.getBoolean("USERSETTING_lan"));
        gool.setChecked(fileManager.getBoolean("USERSETTING_gool"));


        if (!psiphon.isChecked()) {
            countryLayout.setAlpha(0.2f);
            countryLayout.setClickable(false);
        } else {
            countryLayout.setAlpha(1f);
            countryLayout.setClickable(true);
        }
    }

    private void init() {

        fileManager = FileManager.getInstance(getApplicationContext());

        endpointLayout = findViewById(R.id.endpoint_layout);
        portLayout = findViewById(R.id.port_layout);
        splitTunnelLayout = findViewById(R.id.split_tunnel_layout);
        lanLayout = findViewById(R.id.lan_layout);
        psiphonLayout = findViewById(R.id.psiphon_layout);
        countryLayout = findViewById(R.id.country_layout);
        licenseLayout = findViewById(R.id.license_layout);
        goolLayout = findViewById(R.id.gool_layout);

        back = findViewById(R.id.back);
        endpoint = findViewById(R.id.endpoint);
        port = findViewById(R.id.port);
        country = findViewById(R.id.country);
        license = findViewById(R.id.license);

        psiphon = findViewById(R.id.psiphon);
        lan = findViewById(R.id.lan);
        gool = findViewById(R.id.gool);

        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
    }
}