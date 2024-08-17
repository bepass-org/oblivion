package org.bepass.oblivion.ui;

import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ConcatAdapter;

import org.bepass.oblivion.BypassListAppsAdapter;
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.R;
import org.bepass.oblivion.enums.SplitTunnelMode;
import org.bepass.oblivion.SplitTunnelOptionsAdapter;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.databinding.ActivitySplitTunnelBinding;
import org.bepass.oblivion.utils.ThemeHelper;


public class SplitTunnelActivity extends StateAwareBaseActivity<ActivitySplitTunnelBinding> {
    BypassListAppsAdapter bypassListAppsAdapter;

    @Override
    protected int getLayoutResourceId() {
        return R.layout.activity_split_tunnel;
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

        // Handles the back button behaviour
        binding.back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

        // Set up the app list
        bypassListAppsAdapter = new BypassListAppsAdapter(this, loading -> {
            binding.appsRecycler.setVisibility(loading ? View.INVISIBLE : View.VISIBLE);
                if (loading) binding.progress.show();
                else binding.progress.hide();
        });

        // Signal the need to restart the VPN service on app selection change
        bypassListAppsAdapter.setOnAppSelectListener((packageName, selected) -> {
            StateAwareBaseActivity.setRequireRestartVpnService(true);
        });

        // Set behaviour for Split tunnel options
        SplitTunnelOptionsAdapter optionsAdapter = new SplitTunnelOptionsAdapter(this, new SplitTunnelOptionsAdapter.OnSettingsChanged() {
            @Override
            public void splitTunnelMode(SplitTunnelMode mode) {
                StateAwareBaseActivity.setRequireRestartVpnService(true);
                FileManager.set("splitTunnelMode", mode.toString());
            }

            @Override
            public void shouldShowSystemApps(boolean show) {
                bypassListAppsAdapter.setShouldShowSystemApps(show);
            }
        });

        binding.appsRecycler.setAdapter(new ConcatAdapter(optionsAdapter, bypassListAppsAdapter));

        binding.filterListEditText.addTextChangedListener(getTextWatcher());
    }

    private @NonNull TextWatcher getTextWatcher() {
        return new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                if (bypassListAppsAdapter != null) {
                    bypassListAppsAdapter.setFilterString(s.toString());
                }
            }
        };
    }

    @Override
    public void onConnectionStateChange(ConnectionState state) { }

    @NonNull
    @Override
    public String getKey() { return "splitTunnelActivity"; }
}
