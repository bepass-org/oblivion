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
import org.bepass.oblivion.utils.SystemUtils;

/**
 * Activities inheriting from this class observe connection state by default and have access to lastKnownConnectionState variable.
 */
public abstract class StateAwareBaseActivity<B extends ViewDataBinding> extends AppCompatActivity {
    private static final String TAG = "StateAwareBaseActivity";

    protected ConnectionState lastKnownConnectionState = ConnectionState.DISCONNECTED;
    protected B binding;
    private Messenger serviceMessenger;
    private boolean isBound;

    protected abstract int getLayoutResourceId();

    protected abstract int getStatusBarColor();

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = DataBindingUtil.setContentView(this, getLayoutResourceId());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            SystemUtils.setStatusBarColor(
                    this, getStatusBarColor(), ColorUtils.isColorDark(getStatusBarColor())
            );
        }
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
    protected void onResume() {
        super.onResume();
        observeConnectionStatus();
    }

    @Override
    protected void onPause() {
        super.onPause();
        unsubscribeConnectionStatus();
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (isBound) {
            unbindService(connection);
            isBound = false;
        }
    }
}