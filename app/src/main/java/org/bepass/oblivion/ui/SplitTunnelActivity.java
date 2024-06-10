package org.bepass.oblivion.ui;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ConcatAdapter;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.progressindicator.CircularProgressIndicator;

import org.bepass.oblivion.BypassListAppsAdapter;
import org.bepass.oblivion.ConnectionState;
import org.bepass.oblivion.FileManager;
import org.bepass.oblivion.R;
import org.bepass.oblivion.SplitTunnelMode;
import org.bepass.oblivion.SplitTunnelOptionsAdapter;
import org.bepass.oblivion.base.StateAwareBaseActivity;


public class SplitTunnelActivity extends StateAwareBaseActivity {
    private RecyclerView appsRecycler;
    private CircularProgressIndicator progress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Sets the contents from the layout
        setContentView(R.layout.activity_split_tunnel);

        // Find UI elements and assign them to vars
        ImageView back = findViewById(R.id.back);
        appsRecycler = findViewById(R.id.appsRecycler);
        progress = findViewById(R.id.progress);

        // Handles the back button behaviour
        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());

        // Set up the app list
        BypassListAppsAdapter bypassListAppsAdapter = new BypassListAppsAdapter(this, loading -> {
                appsRecycler.setVisibility(loading ? View.INVISIBLE : View.VISIBLE);
                if (loading) progress.show();
                else progress.hide();
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
                FileManager.getInstance(SplitTunnelActivity.this).set("splitTunnelMode", mode.toString());
            }

            @Override
            public void shouldShowSystemApps(boolean show) {
                bypassListAppsAdapter.setShouldShowSystemApps(SplitTunnelActivity.this, show);
            }
        });

        appsRecycler.setAdapter(new ConcatAdapter(optionsAdapter, bypassListAppsAdapter));
    }

    @Override
    void onConnectionStateChange(ConnectionState state) { }

    @NonNull
    @Override
    String getKey() { return "splitTunnelActivity"; }
}
