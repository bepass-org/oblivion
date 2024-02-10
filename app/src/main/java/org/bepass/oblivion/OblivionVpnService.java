package org.bepass.oblivion;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.ParcelFileDescriptor;
import android.os.RemoteException;
import android.util.Log;

import androidx.core.app.NotificationChannelCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import tun2socks.Tun2socks;

import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class OblivionVpnService extends VpnService {
    private static final String TAG = "oblivionVPN";
    public static final String FLAG_VPN_START = "org.bepass.oblivion.START";
    public static final String FLAG_VPN_STOP = "org.bepass.oblivion.STOP";
    private static final String PRIVATE_VLAN4_CLIENT = "172.19.0.1";
    private static final String PRIVATE_VLAN6_CLIENT = "fdfe:dcba:9876::1";
    private Notification notification;
    private ParcelFileDescriptor mInterface;
    private Thread vpnThread;
    private String command;
    private String bindAddress;
    private final Handler handler = new Handler();

    static final int MSG_PERFORM_TASK = 1; // Identifier for the message
    static final int MSG_TASK_COMPLETED = 2; // Identifier for the response
    static final int MSG_TASK_FAILED = 3; // Identifier for the response

    private final Messenger serviceMessenger = new Messenger(new IncomingHandler(this));


    public static Map<String, Integer> splitHostAndPort(String hostPort) {
        if(hostPort == null || hostPort.isEmpty()){
            return null;
        }
        Map<String, Integer> result = new HashMap<>();
        String host;
        int port = -1; // Default port value if not specified

        // Check if the host part is an IPv6 address (enclosed in square brackets)
        if (hostPort.startsWith("[")) {
            int closingBracketIndex = hostPort.indexOf(']');
            if (closingBracketIndex > 0) {
                host = hostPort.substring(1, closingBracketIndex);
                if (hostPort.length() > closingBracketIndex + 1 && hostPort.charAt(closingBracketIndex + 1) == ':') {
                    // There's a port number after the closing bracket
                    port = Integer.parseInt(hostPort.substring(closingBracketIndex + 2));
                }
            } else {
                throw new IllegalArgumentException("Invalid IPv6 address format");
            }
        } else {
            // Handle IPv4 or hostname (split at the last colon)
            int lastColonIndex = hostPort.lastIndexOf(':');
            if (lastColonIndex > 0) {
                host = hostPort.substring(0, lastColonIndex);
                port = Integer.parseInt(hostPort.substring(lastColonIndex + 1));
            } else {
                host = hostPort; // No port specified
            }
        }

        result.put(host, port);
        return result;
    }

    public static String pingOverHTTP(String bindAddress) {
        Map<String, Integer> result = splitHostAndPort(bindAddress);
        if (result == null) {
            return "false";
        }
        String socksHost = result.keySet().iterator().next();
        int socksPort = result.values().iterator().next();

        // Set up the SOCKS proxy
        Proxy proxy = new Proxy(Proxy.Type.SOCKS, new InetSocketAddress(socksHost, socksPort));

        // Create OkHttpClient with SOCKS proxy
        OkHttpClient client = new OkHttpClient.Builder()
                .proxy(proxy)
                .connectTimeout(5, TimeUnit.SECONDS) // 5 seconds connection timeout
                .readTimeout(5, TimeUnit.SECONDS) // 5 seconds read timeout
                .build();

        // Build the request
        Request request = new Request.Builder()
                .url("https://8.8.8.8") // Replace with actual URL
                .build();

        // Execute the request
        try (Response response = client.newCall(request).execute()) {
            return response.isSuccessful() ? "true" : "false";
        } catch (IOException e) {
            return e.getMessage().contains("ECONNREFUSED") || e.getMessage().contains("general failure") ? "false" : "exception";
        }
    }

    private static void performPingTask(Message msg, String bindAddress) {
        new Thread(() -> {
            long startTime = System.currentTimeMillis();
            boolean isSuccessful = false;

            while (System.currentTimeMillis() - startTime < 2 * 60 * 1000) { // 2 minutes
                String result = pingOverHTTP(bindAddress);
                if (result.contains("exception")) {
                    Message replyMsg = Message.obtain(null, MSG_TASK_FAILED);
                    try {
                        msg.replyTo.send(replyMsg);
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                    return;
                }
                if (result.contains("true")) {
                    isSuccessful = true;
                    break;
                }
                try {
                    Thread.sleep(1000); // Sleep for a second before retrying
                } catch (InterruptedException e) {
                    break; // Exit if interrupted (e.g., service stopping)
                }
            }

            Message replyMsg = Message.obtain(null, isSuccessful ? MSG_TASK_COMPLETED : MSG_TASK_FAILED);
            try {
                msg.replyTo.send(replyMsg);
            } catch (RemoteException e) {
                e.printStackTrace();
            }
        }).start();
    }

    private static class IncomingHandler extends Handler {
        private final WeakReference<OblivionVpnService> serviceRef;

        IncomingHandler(OblivionVpnService service) {
            serviceRef = new WeakReference<>(service);
        }
        @Override
        public void handleMessage(Message msg) {
            final Message message = new Message();
            message.copyFrom(msg);
            switch (msg.what) {
                case MSG_PERFORM_TASK:
                    performPingTask(message, serviceRef.get().bindAddress);
                    break;
                default:
                    super.handleMessage(msg);
            }
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return serviceMessenger.getBinder();
    }

    private final Runnable logRunnable = new Runnable() {
        @Override
        public void run() {
            String logMessages = Tun2socks.getLogMessages();
            if (!logMessages.isEmpty()) {
                try (FileOutputStream fos = getApplicationContext().openFileOutput("logs.txt", Context.MODE_APPEND)) {
                    fos.write((logMessages).getBytes());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            handler.postDelayed(this, 2000); // Poll every 2 seconds
        }
    };

    private void clearLogFile() {
        try (FileOutputStream fos = getApplicationContext().openFileOutput("logs.txt", Context.MODE_PRIVATE)) {
            fos.write("".getBytes()); // Overwrite with empty content
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && FLAG_VPN_START.equals(intent.getAction())) {
            command = intent.getStringExtra("command");
            bindAddress = intent.getStringExtra("bindAddress");
            runVpn();
            return START_STICKY;
        } else if (intent != null && FLAG_VPN_STOP.equals(intent.getAction())) {
            stopVpn();
            return START_NOT_STICKY;
        }
        return START_NOT_STICKY;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        handler.post(logRunnable);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        handler.removeCallbacks(logRunnable);
    }

    @Override
    public void onRevoke() {
        super.onRevoke();
    }

    private void runVpn() {
        Log.i(TAG, "Clearing Logs");
        clearLogFile();
        Log.i(TAG, "Create Notification");
        createNotification();
        startForeground(1, notification);
        Log.i(TAG, "Configuring VPN service");
        configure();
    }

    private void stopVpn() {
        Log.i(TAG, "Stopping VPN");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            if (notificationManager != null) {
                notificationManager.deleteNotificationChannel("oblivion");
            }
        }
        try {
            stopForeground(true);
        } catch (Exception e) {
            e.printStackTrace();
        }

        try {
            Tun2socks.shutdown();
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (mInterface != null) {
            try {
                mInterface.close();
            } catch (IOException e) {
                Log.e(TAG, "Error closing the VPN interface", e);
            }
        }

        if(vpnThread != null){
            try {
                vpnThread.join();
                vpnThread.stop();
            } catch (Exception e) {}
        }
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
        try {
            builder.setSession("oblivion")
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
        } catch (PackageManager.NameNotFoundException e) {
            throw new RuntimeException(e);
        }
        mInterface = builder.establish();
        Log.i(TAG, "Interface created");
        vpnThread = new Thread(() -> Tun2socks.runWarp(
                command,
                getApplicationContext().getFilesDir().getAbsolutePath(),
                mInterface.getFd()
        ));
        vpnThread.start();
    }
}