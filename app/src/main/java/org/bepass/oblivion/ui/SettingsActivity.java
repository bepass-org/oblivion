package org.bepass.oblivion.ui;

import static org.bepass.oblivion.utils.BatteryOptimizationKt.isBatteryOptimizationEnabled;
import static org.bepass.oblivion.utils.BatteryOptimizationKt.showBatteryOptimizationDialog;

import android.content.Intent;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.text.InputType;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.CompoundButton;

import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AlertDialog;

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

    private void updateDnsSummary() {
        String primary = FileManager.getString("USERSETTING_dns_primary", "1.1.1.1");
        String secondary = FileManager.getString("USERSETTING_dns_secondary", "1.0.0.1");
        if (binding.dnsDesc != null) {
            String base = getString(R.string.dnsTextDesc);
            String summary = base + " (" + primary + (secondary == null || secondary.trim().isEmpty() ? "" : ", " + secondary.trim()) + ")";
            binding.dnsDesc.setText(summary);
        }
    }

    private void showDnsDialog() {
        final EditText inputPrimary = new EditText(this);
        inputPrimary.setInputType(InputType.TYPE_CLASS_TEXT);
        inputPrimary.setHint("1.1.1.1");
        inputPrimary.setText(FileManager.getString("USERSETTING_dns_primary", "1.1.1.1"));

        final EditText inputSecondary = new EditText(this);
        inputSecondary.setInputType(InputType.TYPE_CLASS_TEXT);
        inputSecondary.setHint("1.0.0.1");
        inputSecondary.setText(FileManager.getString("USERSETTING_dns_secondary", "1.0.0.1"));

        LinearLayout container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        container.setPadding(pad, pad, pad, 0);
        container.addView(inputPrimary);
        container.addView(inputSecondary);

        new AlertDialog.Builder(this)
                .setTitle("DNS")
                .setView(container)
                .setPositiveButton(R.string.update, (d, w) -> {
                    String p = inputPrimary.getText().toString().trim();
                    String s = inputSecondary.getText().toString().trim();
                    if (p.isEmpty()) p = "1.1.1.1";
                    FileManager.set("USERSETTING_dns_primary", p);
                    FileManager.set("USERSETTING_dns_secondary", s);
                    updateDnsSummary();
                    StateAwareBaseActivity.setRequireRestartVpnService(true);
                    Toast.makeText(this, "DNS saved", Toast.LENGTH_SHORT).show();
                })
                .setNegativeButton(R.string.cancel, null)
                .show();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Refresh battery optimization row after returning from settings
        if (isBatteryOptimizationEnabled(this)) {
            binding.batteryOptimizationLayout.setVisibility(View.VISIBLE);
            if (binding.batteryOptLine != null) binding.batteryOptLine.setVisibility(View.VISIBLE);
        } else {
            binding.batteryOptimizationLayout.setVisibility(View.GONE);
            if (binding.batteryOptLine != null) binding.batteryOptLine.setVisibility(View.GONE);
        }
        // Sync MTU text
        if (binding.mtuValue != null) {
            int mtu = FileManager.getInt("USERSETTING_mtu");
            if (mtu <= 0) mtu = 1500;
            binding.mtuValue.setText(String.valueOf(mtu));
        }
        // Sync bypass checkbox
        if (binding.bypassLan != null) {
        }
        // Update DNS summary
        updateDnsSummary();
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
        // Back button in the top bar
        if (binding.back != null) {
            binding.back.setOnClickListener(v -> finish());
        }
        // Set Current Values
        settingBasicValuesFromSPF();

        // Battery optimization prompt row visibility/handler
        if (isBatteryOptimizationEnabled(this)) {
            binding.batteryOptimizationLayout.setVisibility(View.VISIBLE);
            binding.batteryOptimizationLayout.setOnClickListener(view -> {
                showBatteryOptimizationDialog(this);
            });
        } else {
            binding.batteryOptimizationLayout.setVisibility(View.GONE);
            if (binding.batteryOptLine != null) binding.batteryOptLine.setVisibility(View.GONE);
        }

        // Visible MTU row
        if (binding.mtuLayout != null) {
            binding.mtuLayout.setOnClickListener(v -> {
                final EditText input = new EditText(this);
                input.setInputType(InputType.TYPE_CLASS_NUMBER);
                input.setHint("1200-1500");
                new AlertDialog.Builder(this)
                        .setTitle("MTU")
                        .setView(input)
                        .setPositiveButton(R.string.update, (d, w) -> {
                            try {
                                int mtu = Integer.parseInt(input.getText().toString().trim());
                                FileManager.set("USERSETTING_mtu", mtu);
                                if (binding.mtuValue != null) binding.mtuValue.setText(String.valueOf(mtu));
                                StateAwareBaseActivity.setRequireRestartVpnService(true);
                                Toast.makeText(this, "MTU saved", Toast.LENGTH_SHORT).show();
                            } catch (Exception e) {
                                Toast.makeText(this, "Invalid MTU", Toast.LENGTH_SHORT).show();
                            }
                        })
                        .setNegativeButton(R.string.cancel, null)
                        .show();
            });
        }
        binding.splitTunnelLayout.setOnClickListener(v -> startActivity(new Intent(this, SplitTunnelActivity.class)));

        // DNS editor
        if (binding.dnsLayout != null) {
            binding.dnsLayout.setOnClickListener(v -> showDnsDialog());
        }

        binding.goolLayout.setOnClickListener(v -> binding.gool.setChecked(!binding.gool.isChecked()));
        binding.lanLayout.setOnClickListener(v -> binding.lan.setChecked(!binding.lan.isChecked()));
        binding.psiphonLayout.setOnClickListener(v -> binding.psiphon.setChecked(!binding.psiphon.isChecked()));

        binding.lan.setOnCheckedChangeListener((buttonView, isChecked) -> {
            FileManager.set("USERSETTING_lan", isChecked);
        });
        // IPv6 toggle
        binding.ipv6.setOnCheckedChangeListener((buttonView, isChecked) -> {
            FileManager.set("USERSETTING_ipv6", isChecked);
            // If user wants IPv6 and bind host is empty, suggest default ::
            if (isChecked && (FileManager.getString("USERSETTING_bind_host") == null || FileManager.getString("USERSETTING_bind_host").isEmpty())) {
                FileManager.set("USERSETTING_bind_host", "::");
                binding.bindHost.post(() -> binding.bindHost.setText("::"));
            }
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

        // LAN bypass row/checkbox behaves like others
        if (binding.lanBypassLayout != null) {
            binding.lanBypassLayout.setOnClickListener(v -> {
                if (binding.bypassLan != null) {
                    binding.bypassLan.setChecked(!binding.bypassLan.isChecked());
                }
            });
        }
        if (binding.bypassLan != null) {
            binding.bypassLan.setOnCheckedChangeListener((buttonView, isChecked) -> {
                FileManager.set("USERSETTING_bypass_lan", isChecked);
                StateAwareBaseActivity.setRequireRestartVpnService(true);
            });
        }

        // Copy proxy info to clipboard
        binding.copyProxyLayout.setOnClickListener(v -> {
            String host = FileManager.getString("USERSETTING_bind_host");
            boolean lan = FileManager.getBoolean("USERSETTING_lan");
            boolean ipv6 = FileManager.getBoolean("USERSETTING_ipv6");
            String port = FileManager.getString("USERSETTING_port");

            if (host == null || host.trim().isEmpty()) {
                host = ipv6 ? "::" : (lan ? "0.0.0.0" : "127.0.0.1");
            }

            // Bracket IPv6 for host:port
            String hostForString = host;
            if (host.contains(":") && !host.startsWith("[")) {
                hostForString = "[" + host + "]";
            }
            String proxy = hostForString + ":" + port;
            ClipboardManager clipboard = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
            if (clipboard != null) {
                clipboard.setPrimaryClip(ClipData.newPlainText("proxy", proxy));
                // Optional feedback
                // Toast.makeText(this, "Copied: " + proxy, Toast.LENGTH_SHORT).show();
            }
        });
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
        String bindHostVal = FileManager.getString("USERSETTING_bind_host");
        if (bindHostVal == null || bindHostVal.trim().isEmpty()) {
            boolean lan = FileManager.getBoolean("USERSETTING_lan");
            boolean ipv6 = FileManager.getBoolean("USERSETTING_ipv6");
            bindHostVal = ipv6 ? "::" : (lan ? "0.0.0.0" : "127.0.0.1");
        }
        binding.bindHost.setText(bindHostVal);

        int index = FileManager.getInt("USERSETTING_country_index");
        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this, R.array.countries, R.layout.country_item_layout);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        binding.country.post(() -> {
            binding.country.setAdapter(adapter);
            binding.country.setSelection(index);
        });

        binding.psiphon.setChecked(FileManager.getBoolean("USERSETTING_psiphon"));
        binding.lan.setChecked(FileManager.getBoolean("USERSETTING_lan"));
        binding.gool.setChecked(FileManager.getBoolean("USERSETTING_gool"));
        binding.proxyMode.setChecked(FileManager.getBoolean("USERSETTING_proxymode"));
        binding.ipv6.setChecked(FileManager.getBoolean("USERSETTING_ipv6"));
        if (binding.bypassLan != null) {
            binding.bypassLan.setChecked(FileManager.getBoolean("USERSETTING_bypass_lan"));
        }
        if (binding.mtuValue != null) {
            int mtu = FileManager.getInt("USERSETTING_mtu");
            if (mtu <= 0) mtu = 1500;
            binding.mtuValue.setText(String.valueOf(mtu));
        }
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
