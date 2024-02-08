package org.bepass.oblivion;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import org.bepass.oblivion.R;

public class SettingsActivity extends AppCompatActivity {

    FileManager fileManager;
    ImageView back;

    LinearLayout endpointLayout, portLayout, lanLayout, psiphonLayout, countryLayout, licenseLayout, goalLayout;

    TextView endpoint, port, country, license;
    CheckBox psiphon, lan, goal;

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

        goalLayout.setOnClickListener(v -> goal.setChecked(!goal.isChecked()));
        lanLayout.setOnClickListener(v -> lan.setChecked(!lan.isChecked()));
        psiphonLayout.setOnClickListener(v -> psiphon.setChecked(!psiphon.isChecked()));


        psiphon.setOnCheckedChangeListener((buttonView, isChecked) -> {
            fileManager.set("USERSETTING_psiphon", isChecked);
            if (!isChecked) {
                countryLayout.setAlpha(0.2f);
                countryLayout.setClickable(false);
            } else {
                countryLayout.setAlpha(1f);
                countryLayout.setClickable(true);
            }
        });

        lan.setOnCheckedChangeListener((buttonView, isChecked) -> fileManager.set("USERSETTING_lan", isChecked));
        goal.setOnCheckedChangeListener((buttonView, isChecked) -> fileManager.set("USERSETTING_goal", isChecked));

        // Set Current Values
        settingBasicValuesFromSPF();
    }

    private void settingBasicValuesFromSPF() {
        endpoint.setText(fileManager.getString("USERSETTING_endpoint"));
        port.setText(fileManager.getString("USERSETTING_port"));
        country.setText(fileManager.getString("USERSETTING_country"));

        String licenseKey = fileManager.getString("USERSETTING_license");
        if (licenseKey.length() > 8)
            license.setText(licenseKey.substring(0, 8));
        else
            license.setText(licenseKey);

        psiphon.setChecked(fileManager.getBoolean("USERSETTING_psiphon"));
        lan.setChecked(fileManager.getBoolean("USERSETTING_lan"));
        goal.setChecked(fileManager.getBoolean("USERSETTING_goal"));


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
        lanLayout = findViewById(R.id.lan_layout);
        psiphonLayout = findViewById(R.id.psiphon_layout);
        countryLayout = findViewById(R.id.country_layout);
        licenseLayout = findViewById(R.id.license_layout);
        goalLayout = findViewById(R.id.goal_layout);

        back = findViewById(R.id.back);
        endpoint = findViewById(R.id.endpoint);
        port = findViewById(R.id.port);
        country = findViewById(R.id.country);
        license = findViewById(R.id.license);

        psiphon = findViewById(R.id.psiphon);
        lan = findViewById(R.id.lan);
        goal = findViewById(R.id.goal);

        back.setOnClickListener(v -> onBackPressed());
    }
}