package org.bepass.oblivion.ui;

import static org.bepass.oblivion.utils.BatteryOptimizationKt.isBatteryOptimizationEnabled;
import static org.bepass.oblivion.utils.BatteryOptimizationKt.showBatteryOptimizationDialog;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.Nullable;

import org.bepass.oblivion.EditSheet;
import org.bepass.oblivion.EndpointsBottomSheet;
import org.bepass.oblivion.R;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.config.AppConfigManager;
import org.bepass.oblivion.config.EndPoint;
import org.bepass.oblivion.config.EndPointType;
import org.bepass.oblivion.databinding.ActivitySettingsBinding;
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.interfaces.SheetsCallBack;
import org.bepass.oblivion.utils.CountryCode;
import org.bepass.oblivion.utils.CountryUtils;
import org.bepass.oblivion.utils.ThemeHelper;

import kotlin.Triple;

public class SettingsActivity extends StateAwareBaseActivity<ActivitySettingsBinding> {
    private CheckBox.OnCheckedChangeListener psiphonListener;
    private CheckBox.OnCheckedChangeListener goolListener;
    private CompoundButton.OnCheckedChangeListener proxyModeListener;

    public static final String EXTRA_REQUIRE_TO_RESET = "require_to_reset";

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

    private final OnBackPressedCallback onBackPressedCallback = new OnBackPressedCallback(false) {

        @Override
        public void handleOnBackPressed() {
            Toast.makeText(SettingsActivity.this, R.string.to_apply_changes_please_reconnect, Toast.LENGTH_SHORT).show();
            finish();
        }
    };

    private boolean lastKnownStateIsActive() {
        return lastKnownConnectionState == ConnectionState.CONNECTED || lastKnownConnectionState == ConnectionState.CONNECTING;
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

        getOnBackPressedDispatcher().addCallback(this, onBackPressedCallback);

        SheetsCallBack sheetsCallBack = this::settingBasicValuesFromSPF;

        binding.endpointType.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                AppConfigManager.setSettingEndPointType(EndPointType.values()[position]);
                onBackPressedCallback.setEnabled(lastKnownStateIsActive());
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // Do nothing or handle the case where no item is selected.
            }
        });
        binding.endpointLayout.setOnClickListener(v -> {
            EndpointsBottomSheet bottomSheet = new EndpointsBottomSheet();
            bottomSheet.setEndpointSelectionListener(content -> {
                AppConfigManager.setSettingEndPoint(new EndPoint(content));
                binding.endpoint.setText(content);
                onBackPressedCallback.setEnabled(lastKnownStateIsActive());
            });
            bottomSheet.show(getSupportFragmentManager(), bottomSheet.getTag());
        });

        binding.portLayout.setOnClickListener(v -> (new EditSheet(this, getString(R.string.portTunText), "port", sheetsCallBack)).start());
        binding.licenseLayout.setOnClickListener(v -> (new EditSheet(this, getString(R.string.licenseText), "license", sheetsCallBack)).start());

        binding.country.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                String name = parent.getItemAtPosition(position).toString();
                Triple<String, String, Integer> codeAndName = CountryUtils.getCountryCode(getApplicationContext(), name);
                AppConfigManager.setSettingCountry(new CountryCode(codeAndName.getFirst()));
                AppConfigManager.setSettingCountryIndex(position);
                onBackPressedCallback.setEnabled(lastKnownStateIsActive());
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                // Do nothing
            }
        });

        binding.splitTunnelLayout.setOnClickListener(v -> startActivityForResult(new Intent(this, SplitTunnelActivity.class), 1));

        binding.goolLayout.setOnClickListener(v -> binding.gool.setChecked(!binding.gool.isChecked()));
        binding.lanLayout.setOnClickListener(v -> binding.lan.setChecked(!binding.lan.isChecked()));
        binding.psiphonLayout.setOnClickListener(v -> binding.psiphon.setChecked(!binding.psiphon.isChecked()));

        binding.lan.setOnCheckedChangeListener((buttonView, isChecked) -> {
            AppConfigManager.setSettingLan(isChecked);
            onBackPressedCallback.setEnabled(lastKnownStateIsActive());
        });
        psiphonListener = (buttonView, isChecked) -> {
            AppConfigManager.setSettingPsiphon(isChecked);
            if (isChecked && binding.gool.isChecked()) {
                setCheckBoxWithoutTriggeringListener(binding.gool, false, goolListener);
                AppConfigManager.setSettingGool(false);
            }
            binding.countryLayout.setAlpha(isChecked ? 1f : 0.2f);
            binding.country.setEnabled(isChecked);
            onBackPressedCallback.setEnabled(lastKnownStateIsActive());
        };

        goolListener = (buttonView, isChecked) -> {
            AppConfigManager.setSettingGool(isChecked);
            if (isChecked && binding.psiphon.isChecked()) {
                setCheckBoxWithoutTriggeringListener(binding.psiphon, false, psiphonListener);
                AppConfigManager.setSettingPsiphon(false);
                binding.countryLayout.setAlpha(0.2f);
                binding.country.setEnabled(false);
            }
            onBackPressedCallback.setEnabled(lastKnownStateIsActive());
        };

        proxyModeListener = (buttonView, isChecked) -> {
            AppConfigManager.setSettingProxyMode(isChecked);
            onBackPressedCallback.setEnabled(lastKnownStateIsActive());
        };

        binding.txtDarkMode.setOnClickListener(view -> binding.checkBoxDarkMode.setChecked(!binding.checkBoxDarkMode.isChecked()));

        // Set the initial state of the checkbox based on the current theme
        binding.checkBoxDarkMode.setChecked(ThemeHelper.getInstance().getCurrentTheme() == ThemeHelper.Theme.DARK);
        // Set up the listener to change the theme when the checkbox is toggled
        binding.checkBoxDarkMode.setOnCheckedChangeListener((buttonView, isChecked) -> {
            // Determine the new theme based on the checkbox state
            ThemeHelper.Theme newTheme = isChecked ? ThemeHelper.Theme.DARK : ThemeHelper.Theme.LIGHT;

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
        AppConfigManager.resetToDefault();
        onBackPressedCallback.setEnabled(lastKnownStateIsActive());
        getOnBackPressedDispatcher().onBackPressed();
    }

    private void settingBasicValuesFromSPF() {
        ArrayAdapter<CharSequence> etadapter = ArrayAdapter.createFromResource(this, R.array.endpointType, R.layout.country_item_layout);
        etadapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.endpointType.setAdapter(etadapter);
        binding.endpointType.setSelection(AppConfigManager.getSettingEndPointType().ordinal());

        binding.endpoint.setText(AppConfigManager.getSettingEndPoint().getValue());
        binding.port.setText(AppConfigManager.getSettingPort().getValue());
        binding.license.setText(AppConfigManager.getSettingLicense());

        int index = AppConfigManager.getSettingCountryIndex();
        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this, R.array.countries, R.layout.country_item_layout);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.country.setAdapter(adapter);
        binding.country.setSelection(index);

        binding.psiphon.setChecked(AppConfigManager.getSettingPsiphon());
        binding.lan.setChecked(AppConfigManager.getSettingLan());
        binding.gool.setChecked(AppConfigManager.getSettingGool());
        binding.proxyMode.setChecked(AppConfigManager.getSettingProxyMode());
        if (!binding.psiphon.isChecked()) {
            binding.countryLayout.setAlpha(0.2f);
            binding.country.setEnabled(false);
        } else {
            binding.countryLayout.setAlpha(1f);
            binding.country.setEnabled(true);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == resultCode && data != null) {
            onBackPressedCallback.setEnabled(data.getBooleanExtra(EXTRA_REQUIRE_TO_RESET, false) & lastKnownStateIsActive());
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