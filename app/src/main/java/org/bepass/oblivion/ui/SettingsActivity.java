package org.bepass.oblivion.ui;

import static org.bepass.oblivion.utils.BatteryOptimizationKt.isBatteryOptimizationEnabled;
import static org.bepass.oblivion.utils.BatteryOptimizationKt.showBatteryOptimizationDialog;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.CompoundButton;

import androidx.activity.OnBackPressedCallback;

import org.bepass.oblivion.EndpointsBottomSheet;
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.utils.CountryUtils;
import org.bepass.oblivion.EditSheet;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.service.OblivionVpnService;
import org.bepass.oblivion.R;
import org.bepass.oblivion.interfaces.SheetsCallBack;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.databinding.ActivitySettingsBinding;
import org.bepass.oblivion.utils.ThemeHelper;

import kotlin.Triple;

public class SettingsActivity extends StateAwareBaseActivity<ActivitySettingsBinding> {
    private CheckBox.OnCheckedChangeListener psiphonListener;
    private CheckBox.OnCheckedChangeListener goolListener;
    private CompoundButton.OnCheckedChangeListener proxyModeListener;

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
    protected int getStatusBarColor() {
        return R.color.status_bar_color;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Update background based on current theme
        ThemeHelper.getInstance().updateActivityBackground(binding.getRoot());
        // Set Current Values
        settingBasicValuesFromSPF();

        if (isBatteryOptimizationEnabled(this)) {
            binding.batteryOptimizationLayout.setOnClickListener(view -> {
                showBatteryOptimizationDialog(this);
            });
        } else {
            binding.batteryOptimizationLayout.setVisibility(View.GONE);
            binding.batteryOptLine.setVisibility(View.GONE);
        }

        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
//                if (StateAwareBaseActivity.getRequireRestartVpnService()) {
//                    StateAwareBaseActivity.setRequireRestartVpnService(false);
//                    if (!lastKnownConnectionState.isDisconnected()) {
//                        OblivionVpnService.stopVpnService(SettingsActivity.this);
//                        OblivionVpnService.startVpnService(SettingsActivity.this);
//                    }
//                }
                finish();
            }
        });

        SheetsCallBack sheetsCallBack = this::settingBasicValuesFromSPF;

        binding.endpointType.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                FileManager.set("USERSETTING_endpoint_type", position);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // Do nothing or handle the case where no item is selected.
            }
        });
        binding.endpointLayout.setOnClickListener(v -> {
            EndpointsBottomSheet bottomSheet = new EndpointsBottomSheet();
            bottomSheet.setEndpointSelectionListener(content -> {
                Log.d("100","Selected Endpoint: " + content);
                FileManager.set("USERSETTING_endpoint", content);
                binding.endpoint.post(() -> binding.endpoint.setText(content));
            });
            bottomSheet.show(getSupportFragmentManager(), bottomSheet.getTag());
        });

        binding.portLayout.setOnClickListener(v -> (new EditSheet(this, getString(R.string.portTunText), "port", sheetsCallBack)).start());

        binding.country.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String name = parent.getItemAtPosition(position).toString();
                Triple<String, String, Integer> codeAndName = CountryUtils.getCountryCode(getApplicationContext(), name);
                FileManager.set("USERSETTING_country", codeAndName.getFirst());
                FileManager.set("USERSETTING_country_index", position);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // Do nothing
            }
        });

        binding.splitTunnelLayout.setOnClickListener(v -> startActivity(new Intent(this, SplitTunnelActivity.class)));

        binding.goolLayout.setOnClickListener(v -> binding.gool.setChecked(!binding.gool.isChecked()));
        binding.lanLayout.setOnClickListener(v -> binding.lan.setChecked(!binding.lan.isChecked()));
        binding.psiphonLayout.setOnClickListener(v -> binding.psiphon.setChecked(!binding.psiphon.isChecked()));

        binding.lan.setOnCheckedChangeListener((buttonView, isChecked) -> {
            FileManager.set("USERSETTING_lan", isChecked);
        });
        psiphonListener = (buttonView, isChecked) -> {
            FileManager.set("USERSETTING_psiphon", isChecked);
            if (isChecked && binding.gool.isChecked()) {
                binding.gool.post(() -> setCheckBoxWithoutTriggeringListener(binding.gool, false, goolListener));
                FileManager.set("USERSETTING_gool", false);
            }
            binding.countryLayout.setAlpha(isChecked ? 1f : 0.2f);
            binding.country.setEnabled(isChecked);
        };

        goolListener = (buttonView, isChecked) -> {
            FileManager.set("USERSETTING_gool", isChecked);
            if (isChecked && binding.psiphon.isChecked()) {
                binding.psiphon.post(() -> setCheckBoxWithoutTriggeringListener(binding.psiphon, false, psiphonListener));
                FileManager.set("USERSETTING_psiphon", false);
                binding.countryLayout.setAlpha(0.2f);
                binding.country.setEnabled(false);
            }
        };

        proxyModeListener = (buttonView, isChecked) -> {
            FileManager.set("USERSETTING_proxymode", isChecked);
        };

        binding.txtDarkMode.setOnClickListener(view -> binding.switchDarkMode.setChecked(!binding.switchDarkMode.isActivated()));

        // Set the initial state of the switch based on the current theme
        binding.switchDarkMode.setChecked(ThemeHelper.getInstance().getCurrentTheme() == ThemeHelper.Theme.DARK);
        // Set up the listener to change the theme when the switch is toggled
        binding.switchDarkMode.setOnCheckedChangeListener((buttonView, isActive) -> {
            // Determine the new theme based on the switch state
            ThemeHelper.Theme newTheme = isActive ? ThemeHelper.Theme.DARK : ThemeHelper.Theme.LIGHT;
            // Use ThemeHelper to apply the new theme
            ThemeHelper.getInstance().select(newTheme);
        });

        binding.psiphon.setOnCheckedChangeListener(psiphonListener);
        binding.gool.setOnCheckedChangeListener(goolListener);
        binding.resetAppLayout.setOnClickListener(v -> resetAppData());
        binding.proxyModeLayout.setOnClickListener(v -> binding.proxyMode.performClick());
        binding.proxyMode.setOnCheckedChangeListener(proxyModeListener);
    }

    private void resetAppData() {
        FileManager.resetToDefault();
        FileManager.cleanOrMigrateSettings(this);
        Intent intent = new Intent(this, MainActivity.class);
        finish();
        startActivity(intent);
    }
    private void settingBasicValuesFromSPF() {
        ArrayAdapter<CharSequence> etadapter = ArrayAdapter.createFromResource(this, R.array.endpointType, R.layout.country_item_layout);
        etadapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.endpointType.post(() -> {
            binding.endpointType.setAdapter(etadapter);
            binding.endpointType.setSelection(FileManager.getInt("USERSETTING_endpoint_type"));
        });
        binding.endpoint.setText(FileManager.getString("USERSETTING_endpoint"));
        binding.port.setText(FileManager.getString("USERSETTING_port"));

        int index = FileManager.getInt("USERSETTING_country_index");
        String[] countryList = getResources().getStringArray(R.array.countries);
        String[] countryLocaleList = getResources().getStringArray(R.array.localeCountries);
        String[] countryFlagList = new String[countryList.length];
        for (int i= 0;i<countryList.length;i++){
            countryFlagList[i] = countryList[i]+" "+CountryUtils.localeToFlagEmoji(countryLocaleList[i]);
        }
        ArrayAdapter<CharSequence> adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1,countryFlagList);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.country.post(() -> {
            binding.country.setAdapter(adapter);
            binding.country.setSelection(index);
        });

        binding.psiphon.setChecked(FileManager.getBoolean("USERSETTING_psiphon"));
        binding.lan.setChecked(FileManager.getBoolean("USERSETTING_lan"));
        binding.gool.setChecked(FileManager.getBoolean("USERSETTING_gool"));
        binding.proxyMode.setChecked(FileManager.getBoolean("USERSETTING_proxymode"));
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
    public void onConnectionStateChange(ConnectionState state) {
    }
}
