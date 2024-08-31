package org.bepass.oblivion.service;

import static org.bepass.oblivion.ui.MainActivity.startVpnService;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.IBinder;
import android.os.Messenger;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import android.widget.Toast;

import androidx.annotation.RequiresApi;

import org.bepass.oblivion.R;

@RequiresApi(api = Build.VERSION_CODES.N)
public class QuickStartService extends TileService {
    private final static String CONNECTION_OBSERVER_KEY = "quickstartToggleButton";
    private boolean isBound;
    private Messenger serviceMessenger;
    private final ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            serviceMessenger = new Messenger(service);
            isBound = true;
            subscribe();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            serviceMessenger = null;
            isBound = false;
        }
    };


    // Called when your app can update your tile.
    @Override
    public void onStartListening() {
        bindService(new Intent(this, OblivionVpnService.class), connection, Context.BIND_AUTO_CREATE);
    }

    // Called when your app can no longer update your tile.
    @Override
    public void onStopListening() {
        // Unbind from the service
        if (isBound) {
            unsubscribe();
            isBound = false;
        }
        try {
            unbindService(connection);
        } catch (Exception e) {
            //Swallow unbound unbind exceptions
        }
    }

    // Called when the user taps on your tile in an active or inactive state.
    @Override
    public void onClick() {
        Tile tile = getQsTile();
        if (tile == null) {
            return; //Quick setting tile was not registered by system. Return to prevent crash
        }

        if (tile.getState() == Tile.STATE_ACTIVE) {
            OblivionVpnService.stopVpnService(this);
            return;
        }

        if (OblivionVpnService.prepare(this) != null) {
            Toast.makeText(this, "لطفا یک‌بار از درون اپلیکیشن متصل شوید", Toast.LENGTH_LONG).show();
            return;
        }
        Intent vpnIntent = new Intent(this, OblivionVpnService.class);
        startVpnService(this, vpnIntent);
    }

    private void subscribe() {
        if (!isBound) return;
        OblivionVpnService.registerConnectionStateObserver(CONNECTION_OBSERVER_KEY, serviceMessenger, state -> {
            Tile tile = getQsTile();
            if (tile == null) {
                return; //Quick setting tile was not registered by system. Return to prevent crash
            }
            switch (state) {
                case DISCONNECTED:
                    tile.setState(Tile.STATE_INACTIVE);
                    tile.setLabel("Oblivion");
                    tile.setIcon(Icon.createWithResource(getApplicationContext(), R.drawable.vpn_off));
                    tile.updateTile();
                    break;
                case CONNECTING:
                    tile.setState(Tile.STATE_ACTIVE);
                    tile.setLabel("Connecting");
                    tile.setIcon(Icon.createWithResource(getApplicationContext(), R.drawable.vpn_off));
                    tile.updateTile();
                    break;
                case CONNECTED:
                    tile.setState(Tile.STATE_ACTIVE);
                    tile.setLabel("Connected");
                    tile.setIcon(Icon.createWithResource(getApplicationContext(), R.drawable.vpn_on));
                    tile.updateTile();
            }
        });
    }

    private void unsubscribe() {
        if (!isBound) return;
        OblivionVpnService.unregisterConnectionStateObserver(CONNECTION_OBSERVER_KEY, serviceMessenger);
    }
}
