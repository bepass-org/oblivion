package org.bepass.oblivion;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ConcatAdapter;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.progressindicator.CircularProgressIndicator;


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
                    if (!lastKnownConnectionState.isDisconnected()) {
                       OblivionVpnService.stopVpnService(SplitTunnelActivity.this);
                       OblivionVpnService.startVpnService(SplitTunnelActivity.this);
                    }
                }
                finish();
            }
        });

        BypassListAppsAdapter bypassListAppsAdapter = new BypassListAppsAdapter(this, new BypassListAppsAdapter.LoadListener() {
            @Override
            public void onLoad(boolean loading) {
                appsRecycler.setVisibility(loading ? View.INVISIBLE : View.VISIBLE);
                if (loading) progress.show();
                else progress.hide();
            }
        });

        bypassListAppsAdapter.setOnAppSelectListener((packageName, selected) -> {
            settingsChanged = true;
        });
        SplitTunnelOptionsAdapter optionsAdapter = new SplitTunnelOptionsAdapter(this, new SplitTunnelOptionsAdapter.OnSettingsChanged() {

            @Override
            public void splitTunnelMode(SplitTunnelMode mode) {
                settingsChanged = true;
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
    void onConnectionStateChange(ConnectionState state) {

    }

    @NonNull
    @Override
    String getKey() {
        return "splitTunnelActivity";
    }
}
