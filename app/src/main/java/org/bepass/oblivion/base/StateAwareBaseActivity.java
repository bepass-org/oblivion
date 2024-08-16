package org.bepass.oblivion.base;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Messenger;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.databinding.DataBindingUtil;
import androidx.databinding.ViewDataBinding;

import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.service.OblivionVpnService;
import org.bepass.oblivion.utils.ColorUtils;
import org.bepass.oblivion.utils.FileManager;
import org.bepass.oblivion.utils.SystemUtils;

/**
 * Activities inheriting from this class observe connection state by default and have access to lastKnownConnectionState variable.
 */
public abstract class StateAwareBaseActivity<B extends ViewDataBinding> extends AppCompatActivity {
    private static final String TAG = "StateAwareBaseActivity";

    protected ConnectionState lastKnownConnectionState = ConnectionState.DISCONNECTED;
    private static boolean requireRestartVpnService = false;
    protected B binding;
    private Messenger serviceMessenger;
    private boolean isBound;

    protected abstract int getLayoutResourceId();

    protected abstract int getStatusBarColor();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FileManager.initialize(this); // Initialize FileManager with Activity context
        binding = DataBindingUtil.setContentView(this, getLayoutResourceId());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            SystemUtils.setStatusBarColor(
                    this, getStatusBarColor(), ColorUtils.isColorDark(getStatusBarColor())
            );
        }
    }

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

    public void observeConnectionStatus() {
        if (!isBound || serviceMessenger == null) {
            Log.w(TAG, "Service is not bound or messenger is null");
            return;
        }

        OblivionVpnService.registerConnectionStateObserver(getKey(), serviceMessenger, state -> {
            if (lastKnownConnectionState == state) return;
            lastKnownConnectionState = state;
            onConnectionStateChange(state);
        });
    }

    private void unsubscribeConnectionStatus() {
        if (!isBound || serviceMessenger == null) {
            Log.w(TAG, "Service is not bound or messenger is null");
            return;
        }

        OblivionVpnService.unregisterConnectionStateObserver(getKey(), serviceMessenger);
    }

    @Override
    protected void onStart() {
        super.onStart();
        bindService(new Intent(this, OblivionVpnService.class), connection, Context.BIND_AUTO_CREATE);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (isBound) {
            unsubscribeConnectionStatus();
            unbindService(connection);
            isBound = false;
        }
    }
}