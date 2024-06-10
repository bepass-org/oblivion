package org.bepass.oblivion.base;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.os.Messenger;

import androidx.appcompat.app.AppCompatActivity;

import org.bepass.oblivion.ConnectionState;
import org.bepass.oblivion.OblivionVpnService;


/**
 * Those activities that inherit this class observe connection state by default and have access to lastKnownConnectionState variable.
 */
public abstract class StateAwareBaseActivity extends AppCompatActivity {
    protected ConnectionState lastKnownConnectionState = ConnectionState.DISCONNECTED;
    private static boolean requireRestartVpnService = false;
    private Messenger serviceMessenger;
    private boolean isBound;

    public static boolean getRequireRestartVpnService() {
        return requireRestartVpnService;
    }

     public static void setRequireRestartVpnService(boolean b) {
         StateAwareBaseActivity.requireRestartVpnService = b;
    }

    private final ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName className, IBinder service) {
            serviceMessenger = new Messenger(service);
            isBound = true;
            observeConnectionStatus();
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            serviceMessenger = null;
            isBound = false;
        }
    };

    protected abstract String getKey();

    protected abstract void onConnectionStateChange(ConnectionState state);

    private void observeConnectionStatus() {
        if (!isBound) return;
        OblivionVpnService.registerConnectionStateObserver(getKey(), serviceMessenger, state -> {
            if (lastKnownConnectionState == state) return;
            lastKnownConnectionState = state;
            onConnectionStateChange(state);
        });
    }

    private void unsubscribeConnectionStatus() {
        if (!isBound) return;
        OblivionVpnService.unregisterConnectionStateObserver(getKey(), serviceMessenger);
    }

    @Override
    protected void onStart() {
        super.onStart();
        // Bind to the service
        bindService(new Intent(this, OblivionVpnService.class), connection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onStop() {
        super.onStop();
        // Unbind from the service
        if (isBound) {
            unsubscribeConnectionStatus();
            unbindService(connection);
            isBound = false;
        }
    }
}
