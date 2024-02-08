package org.bepass.oblivion;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import androidx.core.app.NotificationChannelCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import tun2socks.Tun2socks;
import java.io.IOException;

public class OblivionVpnService extends VpnService {
    private static final String TAG = "chepassVPN";
    public static final String FLAG_VPN_START = "com.example.chepass.START";
    public static final String FLAG_VPN_STOP = "com.example.chepass.STOP";
    private static final String PRIVATE_VLAN4_CLIENT = "172.19.0.1";
    private static final String PRIVATE_VLAN6_CLIENT = "fdfe:dcba:9876::1";

    private Notification notification;
    private ParcelFileDescriptor mInterface;
    private Thread vpnThread;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && FLAG_VPN_START.equals(intent.getAction())) {
            runVpn();
            return START_STICKY;
        } else if (intent != null && FLAG_VPN_STOP.equals(intent.getAction())) {
            stopVpn();
            return START_NOT_STICKY;
        }
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopVpn();
    }

    @Override
    public void onRevoke() {
        super.onRevoke();
        stopVpn();
    }

    private void runVpn() {
        Log.i(TAG, "Create Notification");
        createNotification();
        startForeground(1, notification);
        Log.i(TAG, "Configuring VPN service");
        configure();
    }

    private void stopVpn() {
        Log.i(TAG, "Stopping VPN");
        Tun2socks.shutdown(); // Signal the Go code to shutdown gracefully
        if (vpnThread != null) {
            vpnThread.interrupt(); // Interrupt the thread
            try {
                vpnThread.join(); // Wait for the thread to finish
            } catch (InterruptedException e) {
                Log.e(TAG, "Failed to join VPN thread", e);
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            if (notificationManager != null) {
                notificationManager.deleteNotificationChannel("chepass");
            }
        }

        if (mInterface != null) {
            try {
                mInterface.close();
            } catch (IOException e) {
                Log.e(TAG, "Error closing the VPN interface", e);
            }
        }
        stopSelf();
        stopForeground(true);
    }

    private void createNotification() {
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
        NotificationChannelCompat notificationChannel = new NotificationChannelCompat.Builder(
                "vpn_service", NotificationManagerCompat.IMPORTANCE_DEFAULT)
                .setName("Vpn service")
                .build();
        notificationManager.createNotificationChannel(notificationChannel);
        PendingIntent contentPendingIntent = PendingIntent.getActivity(
                this, 2, new Intent(this, MainActivity.class), PendingIntent.FLAG_IMMUTABLE);
        notification = new NotificationCompat.Builder(this, notificationChannel.getId())
                .setContentTitle("Vpn service")
                .setContentText("Testing Tun2Socks")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOnlyAlertOnce(true)
                .setOngoing(true)
                .setAutoCancel(true)
                .setShowWhen(false)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setDefaults(NotificationCompat.FLAG_ONLY_ALERT_ONCE)
                .setContentIntent(contentPendingIntent)
                .build();
    }

    private void configure() {
        VpnService.Builder builder = new VpnService.Builder();
        builder.setSession("chepass")
                .setMtu(1500)
                .addAddress(PRIVATE_VLAN4_CLIENT, 30)
                .addAddress(PRIVATE_VLAN6_CLIENT, 126)
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .addDnsServer("1.1.1.1")
                .addDnsServer("1.0.0.1")
                .addDnsServer("2001:4860:4860::8888")
                .addDnsServer("2001:4860:4860::8844")
                .addDisallowedApplication(getPackageName())
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0);
        mInterface = builder.establish();
        Log.i(TAG, "Interface created");
        vpnThread = new Thread(new Runnable() {
            @Override
            public void run() {
                Tun2socks.runWarp(
                        "-gool",
                        Integer.toString(mInterface.getFd()),
                        getApplicationContext().getFilesDir().getAbsolutePath()
                );
            }
        });
        vpnThread.start();
    }
}