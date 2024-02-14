package org.bepass.oblivion.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.activity.OnBackPressedCallback;
import androidx.recyclerview.widget.ConcatAdapter;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.progressindicator.CircularProgressIndicator;

import org.bepass.oblivion.FileManager;
import org.bepass.oblivion.R;
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.enums.SplitTunnelMode;
import org.bepass.oblivion.recycler_adapters.InstalledAppsAdapter;
import org.bepass.oblivion.recycler_adapters.SplitTunnelOptionsAdapter;
import org.bepass.oblivion.services.OblivionVpnService;

public class SplitTunnelActivity extends ConnectionAwareBaseActivity {

    private ImageView back;
    private RecyclerView appsRecycler;
    private CircularProgressIndicator progress;
    private boolean settingsChanged = false;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_split_tunnel);
        back = findViewById(R.id.back);
        appsRecycler = findViewById(R.id.appsRecycler);
        progress = findViewById(R.id.progress);

        back.setOnClickListener(v -> getOnBackPressedDispatcher().onBackPressed());
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (settingsChanged) {
                    settingsChanged = false;
                    if (lastKnownConnectionState.connectedOrConnecting()) {
                        OblivionVpnService.stopVpnService(SplitTunnelActivity.this);
                        OblivionVpnService.startVpnService(SplitTunnelActivity.this);
                    }
                }
                finish();
            }
        });

        InstalledAppsAdapter installedAppsAdapter = new InstalledAppsAdapter(this, new InstalledAppsAdapter.LoadListener() {
            @Override
            public void onLoad(boolean loading) {
                appsRecycler.setVisibility(loading ? View.INVISIBLE : View.VISIBLE);
                if (loading) progress.show(); else progress.hide();
            }
        });

        installedAppsAdapter.setOnAppSelectListener((packageName, selected) -> { settingsChanged = true; } );
        SplitTunnelOptionsAdapter optionsAdapter = new SplitTunnelOptionsAdapter(this, new SplitTunnelOptionsAdapter.OnSettingsChanged() {

            @Override
            public void splitTunnelMode(SplitTunnelMode mode) {
                settingsChanged = true;
                FileManager.getInstance(SplitTunnelActivity.this).set("splitTunnelMode", mode.toString());
            }

            @Override
            public void shouldShowSystemApps(boolean show) {
                installedAppsAdapter.setShouldShowSystemApps(SplitTunnelActivity.this, show);
            }
        });

        appsRecycler.setAdapter(new ConcatAdapter(optionsAdapter, installedAppsAdapter));
    }

    @Override
    void onConnectionStateChange(ConnectionState state) {

    }

    @Override
    String getKey() {
        return "splitTunnelActivity";
    }


}