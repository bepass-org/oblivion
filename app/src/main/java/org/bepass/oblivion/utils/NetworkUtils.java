package org.bepass.oblivion.utils;

import static org.bepass.oblivion.service.OblivionVpnService.stopVpnService;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Handler;

import org.bepass.oblivion.enums.ConnectionState;

import java.util.Locale;

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
    public static String getLocalIpAddress(Context context) throws Exception {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = connectivityManager.getActiveNetworkInfo();

        if (activeNetwork != null && activeNetwork.isConnected()) {
            if (activeNetwork.getType() == ConnectivityManager.TYPE_WIFI) {
                // Get IP Address from Wi-Fi
                WifiManager wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                int ipAddress = wifiManager.getConnectionInfo().getIpAddress();
                return String.format(Locale.US, "%d.%d.%d.%d",
                        (ipAddress & 0xff),
                        (ipAddress >> 8 & 0xff),
                        (ipAddress >> 16 & 0xff),
                        (ipAddress >> 24 & 0xff));
            } else if (activeNetwork.getType() == ConnectivityManager.TYPE_MOBILE) {
                // Throw exception if connected to Mobile Data (4G)
                throw new Exception("Operation not allowed on cellular data (4G). Please connect to Wi-Fi.");
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            NetworkCapabilities capabilities = connectivityManager.getNetworkCapabilities(connectivityManager.getActiveNetwork());
            if (capabilities != null && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                // Get IP Address from Wi-Fi
                WifiManager wifiManager = (WifiManager) context.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                int ipAddress = wifiManager.getConnectionInfo().getIpAddress();
                return String.format(Locale.US, "%d.%d.%d.%d",
                        (ipAddress & 0xff),
                        (ipAddress >> 8 & 0xff),
                        (ipAddress >> 16 & 0xff),
                        (ipAddress >> 24 & 0xff));
            } else if (capabilities != null && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                // Throw exception if connected to Mobile Data (4G)
                throw new Exception("Operation not allowed on cellular data (4G). Please connect to Wi-Fi.");
            }
        }

        return null; // Return null if no connection is available
    }


}
