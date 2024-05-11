package org.bepass.oblivion;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.activity.OnBackPressedCallback;

public class SettingsActivity extends StateAwareBaseActivity {
    private FileManager fileManager;
    private LinearLayout countryLayout;
    private TextView endpoint, port, license;
    private CheckBox psiphon, lan, gool;
    private Spinner country;
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

        fileManager = FileManager.getInstance(getApplicationContext());

        LinearLayout endpointLayout = findViewById(R.id.endpoint_layout);
        LinearLayout portLayout = findViewById(R.id.port_layout);
        LinearLayout splitTunnelLayout = findViewById(R.id.split_tunnel_layout);
        LinearLayout lanLayout = findViewById(R.id.lan_layout);
        LinearLayout psiphonLayout = findViewById(R.id.psiphon_layout);
        countryLayout = findViewById(R.id.country_layout);
        LinearLayout licenseLayout = findViewById(R.id.license_layout);
        LinearLayout goolLayout = findViewById(R.id.gool_layout);

        endpoint = findViewById(R.id.endpoint);
        port = findViewById(R.id.port);
        country = findViewById(R.id.country);
        license = findViewById(R.id.license);

        psiphon = findViewById(R.id.psiphon);
        lan = findViewById(R.id.lan);
        gool = findViewById(R.id.gool);

        ImageView back = findViewById(R.id.back);
        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (StateAwareBaseActivity.getRequireRestartVpnService()) {
                    StateAwareBaseActivity.setRequireRestartVpnService(false);
                    if (!lastKnownConnectionState.isDisconnected()) {
                        OblivionVpnService.stopVpnService(SettingsActivity.this);
                        OblivionVpnService.startVpnService(SettingsActivity.this);
                    }
                }
                finish();
            }
        });

        SheetsCallBack sheetsCallBack = this::settingBasicValuesFromSPF;
        // Listen to Changes
        endpointLayout.setOnClickListener(v -> (new EditSheet(this, "اندپوینت", "endpoint", sheetsCallBack)).start());
        portLayout.setOnClickListener(v -> (new EditSheet(this, "پورت", "port", sheetsCallBack)).start());
        licenseLayout.setOnClickListener(v -> (new EditSheet(this, "لایسنس", "license", sheetsCallBack)).start());

        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this, R.array.countries, R.layout.country_item_layout);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        country.setAdapter(adapter);

        country.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView parent, View view, int position, long id) {
                String name = parent.getItemAtPosition(position).toString();
                String code = CountryUtils.getCountryCode(name);
                fileManager.set("USERSETTING_country", code);
            }

            @Override
            public void onNothingSelected(AdapterView parent) {}
        });

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
            country.setEnabled(isChecked);
        };

        goolListener = (buttonView, isChecked) -> {
            fileManager.set("USERSETTING_gool", isChecked);
            if (isChecked && psiphon.isChecked()) {
                setCheckBoxWithoutTriggeringListener(psiphon, false, psiphonListener);
                fileManager.set("USERSETTING_psiphon", false);
                countryLayout.setAlpha(0.2f);
                country.setEnabled(false);
            }
        };

        // Set the listeners to the checkboxes
        psiphon.setOnCheckedChangeListener(psiphonListener);
        gool.setOnCheckedChangeListener(goolListener);
    }

    private int getIndexFromName(Spinner spinner, String name) {
        for (int i = 0; i < spinner.getCount(); i++) {
            if (spinner.getItemAtPosition(i).toString().equals(name)) {
                return i;
            }
        }

        return 0;
    }

    private void settingBasicValuesFromSPF() {
        endpoint.setText(fileManager.getString("USERSETTING_endpoint"));
        port.setText(fileManager.getString("USERSETTING_port"));
        license.setText(fileManager.getString("USERSETTING_license"));

        String countryCode = fileManager.getString("USERSETTING_country");
        int index = 0;
        if (!countryCode.isEmpty()) {
            String countryName = CountryUtils.getCountryName(countryCode);
            index = getIndexFromName(country, countryName);
        }
        country.setSelection(index);

        psiphon.setChecked(fileManager.getBoolean("USERSETTING_psiphon"));
        lan.setChecked(fileManager.getBoolean("USERSETTING_lan"));
        gool.setChecked(fileManager.getBoolean("USERSETTING_gool"));


        if (!psiphon.isChecked()) {
            countryLayout.setAlpha(0.2f);
            country.setEnabled(false);
        } else {
            countryLayout.setAlpha(1f);
            country.setEnabled(true);
        }
    }

    @Override
    String getKey() {
        return "settingsActivity";
    }

    @Override
    void onConnectionStateChange(ConnectionState state) {}
}
