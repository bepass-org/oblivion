package org.bepass.oblivion.utils;

import static org.bepass.oblivion.service.OblivionVpnService.stopVpnService;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.os.Build;
import android.os.Handler;

import org.bepass.oblivion.enums.ConnectionState;

public class NetworkUtils {

    private static final Handler handler = new Handler();
    public static void monitorInternetConnection(ConnectionState lastKnownConnectionState, Context context) {
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (!lastKnownConnectionState.isDisconnected()) {
                    checkInternetConnectionAndDisconnectVPN(context);
                    handler.postDelayed(this, 3000); // Check every 3 seconds
                }
            }
        }, 5000); // Start checking after 5 seconds
    }
    // Periodically check internet connection and disconnect VPN if not connected
    private static void checkInternetConnectionAndDisconnectVPN(Context context) {
        if (!isConnectedToInternet(context)) {
            stopVpnService(context);
        }
    }

    private static boolean isConnectedToInternet(Context context) {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        if (connectivityManager != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Network activeNetwork = connectivityManager.getActiveNetwork();
                if (activeNetwork != null) {
                    NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork);
                    return networkCapabilities != null &&
                            (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR));
                }
            } else {
                // For API levels below 23, use the deprecated method
                NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();
                return activeNetwork != null && activeNetwork.isConnectedOrConnecting();
            }
        }
        return false;
    }
}
