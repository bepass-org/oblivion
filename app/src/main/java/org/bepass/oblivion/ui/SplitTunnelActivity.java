package org.bepass.oblivion.ui;

import static org.bepass.oblivion.ui.SettingsActivity.EXTRA_REQUIRE_TO_RESET;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ConcatAdapter;

import org.bepass.oblivion.BypassListAppsAdapter;
import org.bepass.oblivion.R;
import org.bepass.oblivion.SplitTunnelOptionsAdapter;
import org.bepass.oblivion.base.StateAwareBaseActivity;
import org.bepass.oblivion.config.AppConfigManager;
import org.bepass.oblivion.databinding.ActivitySplitTunnelBinding;
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.enums.SplitTunnelMode;
import org.bepass.oblivion.utils.ThemeHelper;


public class SplitTunnelActivity extends StateAwareBaseActivity<ActivitySplitTunnelBinding> {

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
        BypassListAppsAdapter bypassListAppsAdapter = new BypassListAppsAdapter(this, loading -> {
            binding.appsRecycler.setVisibility(loading ? View.INVISIBLE : View.VISIBLE);
            if (loading) binding.progress.show(); else binding.progress.hide();
        });

        // Signal the need to restart the VPN service on app selection change
        bypassListAppsAdapter.setOnAppSelectListener((packageName, selected) -> {
            setResult(1, new Intent().putExtra(EXTRA_REQUIRE_TO_RESET, true));
        });

        // Set behaviour for Split tunnel options
        SplitTunnelOptionsAdapter optionsAdapter = new SplitTunnelOptionsAdapter(this, new SplitTunnelOptionsAdapter.OnSettingsChanged() {
            @Override
            public void splitTunnelMode(SplitTunnelMode mode) {
                setResult(1, new Intent().putExtra(EXTRA_REQUIRE_TO_RESET, true));
                AppConfigManager.setSplitTunnelMode(mode);
            }

            @Override
            public void shouldShowSystemApps(boolean show) {
                bypassListAppsAdapter.setShouldShowSystemApps(SplitTunnelActivity.this, show);
            }
        });

        binding.appsRecycler.setAdapter(new ConcatAdapter(optionsAdapter, bypassListAppsAdapter));
    }

    @Override
    public void onConnectionStateChange(ConnectionState state) { }

    @NonNull
    @Override
    public String getKey() { return "splitTunnelActivity"; }
}
