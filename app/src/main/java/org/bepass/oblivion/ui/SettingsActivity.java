package org.bepass.oblivion.ui;

import static org.bepass.oblivion.BatteryOptimizationKt.isBatteryOptimizationEnabled;
import static org.bepass.oblivion.BatteryOptimizationKt.showBatteryOptimizationDialog;

import android.content.Intent;
import android.os.Bundle;
import android.util.Pair;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.Spinner;

import androidx.activity.OnBackPressedCallback;

import org.bepass.oblivion.ConnectionState;
import org.bepass.oblivion.utils.CountryUtils;
import org.bepass.oblivion.EditSheet;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.utils.LocaleHelper;
import org.bepass.oblivion.service.OblivionVpnService;
import org.bepass.oblivion.R;
import org.bepass.oblivion.SheetsCallBack;
import org.bepass.oblivion.base.ApplicationLoader;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.databinding.ActivitySettingsBinding;

public class SettingsActivity extends StateAwareBaseActivity<ActivitySettingsBinding> {
    private FileManager fileManager;
    private CheckBox.OnCheckedChangeListener psiphonListener;
    private CheckBox.OnCheckedChangeListener goolListener;
    private void setCheckBoxWithoutTriggeringListener(CheckBox checkBox, boolean isChecked, CheckBox.OnCheckedChangeListener listener) {
        checkBox.setOnCheckedChangeListener(null); // Temporarily detach the listener
        checkBox.setChecked(isChecked); // Set the checked state
        checkBox.setOnCheckedChangeListener(listener); // Reattach the listener
    }

    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_settings;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        fileManager = FileManager.getInstance(this);

        if(isBatteryOptimizationEnabled(this)){
            binding.batteryOptimizationLayout.setOnClickListener(view -> {
                showBatteryOptimizationDialog(this);
            });
        }else{
            binding.batteryOptimizationLayout.setVisibility(View.GONE);
            binding.batteryOptLine.setVisibility(View.GONE);
        }


        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

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
        binding.endpointLayout.setOnClickListener(v -> (new EditSheet(this, getString(R.string.endpointText), "endpoint", sheetsCallBack)).start());
        binding.portLayout.setOnClickListener(v -> (new EditSheet(this, getString(R.string.portTunText), "port", sheetsCallBack)).start());
        binding.licenseLayout.setOnClickListener(v -> (new EditSheet(this, getString(R.string.licenseText), "license", sheetsCallBack)).start());

        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this, R.array.countries, R.layout.country_item_layout);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.country.setAdapter(adapter);

        binding.country.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView parent, View view, int position, long id) {
                String name = parent.getItemAtPosition(position).toString();
                Pair<String, String> codeAndName = CountryUtils.getCountryCode(ApplicationLoader.getAppCtx(), name);
                fileManager.set("USERSETTING_country", codeAndName.first);
            }

            @Override
            public void onNothingSelected(AdapterView parent) {}
        });

        binding.splitTunnelLayout.setOnClickListener(v -> startActivity(new Intent(this, SplitTunnelActivity.class)));

        // Set Current Values
        settingBasicValuesFromSPF();

        binding.goolLayout.setOnClickListener(v -> binding.gool.setChecked(!binding.gool.isChecked()));
        binding.lanLayout.setOnClickListener(v -> binding.lan.setChecked(!binding.lan.isChecked()));
        binding.psiphonLayout.setOnClickListener(v -> binding.psiphon.setChecked(!binding.psiphon.isChecked()));

        binding.lan.setOnCheckedChangeListener((buttonView, isChecked) -> fileManager.set("USERSETTING_lan", isChecked));
        // Initialize the listeners
        psiphonListener = (buttonView, isChecked) -> {
            fileManager.set("USERSETTING_psiphon", isChecked);
            if (isChecked && binding.gool.isChecked()) {
                setCheckBoxWithoutTriggeringListener(binding.gool, false, goolListener);
                fileManager.set("USERSETTING_gool", false);
            }
            binding.countryLayout.setAlpha(isChecked ? 1f : 0.2f);
            binding.country.setEnabled(isChecked);
        };

        goolListener = (buttonView, isChecked) -> {
            fileManager.set("USERSETTING_gool", isChecked);
            if (isChecked && binding.psiphon.isChecked()) {
                setCheckBoxWithoutTriggeringListener(binding.psiphon, false, psiphonListener);
                fileManager.set("USERSETTING_psiphon", false);
                binding.countryLayout.setAlpha(0.2f);
                binding.country.setEnabled(false);
            }
        };

        // Set the listeners to the checkboxes
        binding.psiphon.setOnCheckedChangeListener(psiphonListener);
        binding.gool.setOnCheckedChangeListener(goolListener);
    }

    private int getIndexFromName(Spinner spinner, String name) {
        String ccn = CountryUtils.getCountryName(name);
        String newname = LocaleHelper.restoreText(this,ccn);
        for (int i = 0; i < spinner.getCount(); i++) {
            if (spinner.getItemAtPosition(i).toString().equalsIgnoreCase(newname)) {
                return i;
            }
        }

        return 0;
    }

    private void settingBasicValuesFromSPF() {
        binding.endpoint.setText(fileManager.getString("USERSETTING_endpoint"));
        binding.port.setText(fileManager.getString("USERSETTING_port"));
        binding.license.setText(fileManager.getString("USERSETTING_license"));

        String countryCode = fileManager.getString("USERSETTING_country");
        int index = 0;
        if (!countryCode.isEmpty()) {
            LocaleHelper.goEn(this);
            String countryName = CountryUtils.getCountryName(countryCode);
            index = getIndexFromName(binding.country, countryName);
            LocaleHelper.restoreLocale(this);
        }
        binding.country.setSelection(index);

        binding.psiphon.setChecked(fileManager.getBoolean("USERSETTING_psiphon"));
        binding.lan.setChecked(fileManager.getBoolean("USERSETTING_lan"));
        binding.gool.setChecked(fileManager.getBoolean("USERSETTING_gool"));


        if (!binding.psiphon.isChecked()) {
            binding.countryLayout.setAlpha(0.2f);
            binding.country.setEnabled(false);
        } else {
            binding.countryLayout.setAlpha(1f);
            binding.country.setEnabled(true);
        }
    }

    @Override
    public String getKey() {
        return "settingsActivity";
    }

    @Override
    public void onConnectionStateChange(ConnectionState state) {}
}
