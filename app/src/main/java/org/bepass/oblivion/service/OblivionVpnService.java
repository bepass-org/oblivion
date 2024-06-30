package org.bepass.oblivion.service;

import static android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.ParcelFileDescriptor;
import android.os.PowerManager;
import android.os.RemoteException;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationChannelCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import org.bepass.oblivion.ConnectionState;
import org.bepass.oblivion.ConnectionStateChangeListener;
import org.bepass.oblivion.R;
import org.bepass.oblivion.SplitTunnelMode;
import org.bepass.oblivion.ui.MainActivity;
import org.bepass.oblivion.utils.FileManager;

import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.ServerSocket;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import tun2socks.StartOptions;
import tun2socks.Tun2socks;

public class OblivionVpnService extends VpnService {
    public static final String FLAG_VPN_START = "org.bepass.oblivion.START";
    public static final String FLAG_VPN_STOP = "org.bepass.oblivion.STOP";
    static final int MSG_CONNECTION_STATE_SUBSCRIBE = 1;
    static final int MSG_CONNECTION_STATE_UNSUBSCRIBE = 2;
    static final int MSG_TILE_STATE_SUBSCRIPTION_RESULT = 3;

    private static final String TAG = "oblivionVPN";
    private static final String PRIVATE_VLAN4_CLIENT = "172.19.0.1";
    private static final String PRIVATE_VLAN6_CLIENT = "fdfe:dcba:9876::1";
    private final Handler handler = new Handler();
    private final Messenger serviceMessenger = new Messenger(new IncomingHandler(this));
    private final Map<String, Messenger> connectionStateObservers = new HashMap<>();
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
    // For JNI Calling in a new threa
    private final Executor executorService = Executors.newSingleThreadExecutor();
    // For PingHTTPTestConnection to don't busy-waiting
    private ScheduledExecutorService scheduler;
    private Notification notification;
    private ParcelFileDescriptor mInterface;
    private String bindAddress;
    private FileManager fileManager;
    private static PowerManager.WakeLock wLock;
    private ConnectionState lastKnownState = ConnectionState.DISCONNECTED;

    public static synchronized void startVpnService(Context context) {
        Intent intent = new Intent(context, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_START);
        ContextCompat.startForegroundService(context, intent);
    }


    public static synchronized void stopVpnService(Context context) {
        Intent intent = new Intent(context, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_STOP);
        ContextCompat.startForegroundService(context, intent);
    }
    public static void registerConnectionStateObserver(String key, Messenger serviceMessenger, ConnectionStateChangeListener observer) {
        // Create a message for the service
        Message subscriptionMessage = Message.obtain(null, OblivionVpnService.MSG_CONNECTION_STATE_SUBSCRIBE);
        Bundle data = new Bundle();
        data.putString("key", key);
        subscriptionMessage.setData(data);
        // Create a Messenger for the reply from the service
        subscriptionMessage.replyTo = new Messenger(new Handler(incomingMessage -> {
            ConnectionState state = ConnectionState.valueOf(incomingMessage.getData().getString("state"));
            if (incomingMessage.what == OblivionVpnService.MSG_TILE_STATE_SUBSCRIPTION_RESULT) {
                observer.onChange(state);
            }
            return true;
        }));
        try {
            // Send the message
            serviceMessenger.send(subscriptionMessage);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    public static void unregisterConnectionStateObserver(String key, Messenger serviceMessenger) {
        Message unsubscriptionMessage = Message.obtain(null, OblivionVpnService.MSG_CONNECTION_STATE_UNSUBSCRIBE);
        Bundle data = new Bundle();
        data.putString("key", key);
        unsubscriptionMessage.setData(data);
        try {
            serviceMessenger.send(unsubscriptionMessage);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    public static Map<String, Integer> splitHostAndPort(String hostPort) {
        if (hostPort == null || hostPort.isEmpty()) {
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

    private static int findFreePort() {
        try (ServerSocket socket = new ServerSocket(0)) {
            socket.setReuseAddress(true);
            int port = socket.getLocalPort();
            try {
                socket.close();
            } catch (IOException e) {
                // Ignore IOException on close()
            }
            return port;
        } catch (IOException ignored) {
        }
        throw new IllegalStateException("Could not find a free TCP/IP port to start embedded Jetty HTTP Server on");
    }

    public static boolean pingOverHTTP(String bindAddress) {
        System.out.println("Pinging");
       Map<String, Integer> result = splitHostAndPort(bindAddress);
       if (result == null) {
           throw new RuntimeException("Could not split host and port of " + bindAddress);
       }
       String socksHost = result.keySet().iterator().next();
       int socksPort = result.values().iterator().next();
       Proxy proxy = new Proxy(Proxy.Type.SOCKS, new InetSocketAddress(socksHost, socksPort));
       OkHttpClient client = new OkHttpClient.Builder()
               .proxy(proxy)
               .connectTimeout(5, TimeUnit.SECONDS) // 5 seconds connection timeout
               .readTimeout(5, TimeUnit.SECONDS) // 5 seconds read timeout
               .build();
       Request request = new Request.Builder()
               .url("https://www.gstatic.com/generate_204")
               .build();
       try (Response response = client.newCall(request).execute()) {
           return response.isSuccessful();
       } catch (IOException e) {
           //e.printStackTrace();
           return false;
       }
    }


    public static String isLocalPortInUse(String bindAddress) {
        Map<String, Integer> result = splitHostAndPort(bindAddress);
        if (result == null) {
            return "exception";
        }
        int socksPort = result.values().iterator().next();
        try {
            // ServerSocket try to open a LOCAL port
            new ServerSocket(socksPort).close();
            // local port can be opened, it's available
            return "false";
        } catch (IOException e) {
            // local port cannot be opened, it's in use
            return "true";
        }
    }

    private Set<String> getSplitTunnelApps() {
        return fileManager.getStringSet("splitTunnelApps", new HashSet<>());
    }


    private void performConnectionTest(String bindAddress, ConnectionStateChangeListener changeListener) {
        if (changeListener == null) {
            return;
        }

        scheduler = Executors.newScheduledThreadPool(1);

        final long startTime = System.currentTimeMillis();
        final long timeout = 60 * 1000; // 1 minute

        Runnable pingTask = () -> {
            if (System.currentTimeMillis() - startTime >= timeout) {
                changeListener.onChange(ConnectionState.DISCONNECTED);
                stopForegroundService();
                scheduler.shutdown();
                return;
            }

            boolean result = pingOverHTTP(bindAddress);
            if (result) {
                changeListener.onChange(ConnectionState.CONNECTED);
                scheduler.shutdown();
            }
        };


        // Schedule the ping task to run with a fixed delay of 1 second
        scheduler.scheduleWithFixedDelay(pingTask, 0, 1, TimeUnit.SECONDS);
    }

    private void stopForegroundService() {
        stopForeground(true);
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.cancel(1);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                notificationManager.deleteNotificationChannel("oblivion");
            }
        }
    }

    private String getBindAddress() {
        String port = fileManager.getString("USERSETTING_port");
        boolean enableLan = fileManager.getBoolean("USERSETTING_lan");
        if (OblivionVpnService.isLocalPortInUse("127.0.0.1:" + port).equals("true")) {
            port = String.valueOf(findFreePort());
        }
        String Bind = "";
        Bind += "127.0.0.1:" + port;
        if (enableLan) {
            Bind = "0.0.0.0:" + port;
        }
        return Bind;
    }

    @Override
    public IBinder onBind(Intent intent) {
        String action = intent != null ? intent.getAction() : null;
        /*
        If we override onBind, we never receive onRevoke.
        return superclass onBind when action is SERVICE_INTERFACE to receive onRevoke lifecycle call.
         */
        if (action != null && action.equals(VpnService.SERVICE_INTERFACE)) {
            return super.onBind(intent);
        }
        return serviceMessenger.getBinder();
    }

    private void clearLogFile() {
        try (FileOutputStream fos = getApplicationContext().openFileOutput("logs.txt", Context.MODE_PRIVATE)) {
            fos.write("".getBytes()); // Overwrite with empty content
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void start() {
        // If there's an existing running service, revoke it first
        if (lastKnownState != ConnectionState.DISCONNECTED) {
            onRevoke();
        }

        fileManager = FileManager.getInstance(this);

        setLastKnownState(ConnectionState.CONNECTING);
        Log.i(TAG, "Clearing Logs");
        clearLogFile();
        Log.i(TAG, "Create Notification");
        createNotification();
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.TIRAMISU) {
            startForeground(1, notification);
        } else {
            startForeground(1, notification, FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED);
        }

        if (wLock == null) {
            wLock = ((PowerManager) getSystemService(Context.POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "oblivion:vpn");
            wLock.setReferenceCounted(false);
            wLock.acquire(3*60*1000L /*3 minutes*/);
        }

        executorService.execute(() -> {
            bindAddress = getBindAddress();
            Log.i(TAG, "Configuring VPN service");
            try {
                configure();
            } catch (Exception e) {
                onRevoke();
                e.printStackTrace();
                return;
            }

            performConnectionTest(bindAddress, (state) -> {
                if (state == ConnectionState.DISCONNECTED) {
                    onRevoke();
                }
                setLastKnownState(state);
                // Re-create the notification when the connection state changes
                createNotification();
                startForeground(1, notification); // Start foreground again after connection
            });
        });
    }

    @Override
    public synchronized int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) {
            return START_NOT_STICKY;
        }

        String action = intent.getAction();
        if (action == null) {
            return START_NOT_STICKY;
        }

        switch (action) {
            case FLAG_VPN_START:
                start();
                return START_STICKY;

            case FLAG_VPN_STOP:
                onRevoke();
                return START_NOT_STICKY;

            default:
                return START_NOT_STICKY;
        }
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
        if (wLock != null && wLock.isHeld()) {
            wLock.release();
            wLock = null;
        }
    }

    @Override
    public void onRevoke() {
        setLastKnownState(ConnectionState.DISCONNECTED);
        Log.i(TAG, "Stopping VPN");

        stopForegroundService();

        // Release the wake lock if held
        try {
            if (wLock != null && wLock.isHeld()) {
                wLock.release();
                wLock = null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error releasing wake lock", e);
        }

        // Close the VPN interface
        try {
            if (mInterface != null) {
                mInterface.close();
            }
        } catch (IOException e) {
            Log.e(TAG, "Error closing the VPN interface", e);
        }

        // Stop Tun2socks
        try {
            Tun2socks.stop();
        } catch (Exception e) {
            Log.e(TAG, "Error stopping Tun2socks", e);
        }

        // Shutdown executor service
        if (executorService instanceof ExecutorService) {
            ExecutorService service = (ExecutorService) executorService;
            service.shutdown(); // Attempt to gracefully shutdown
            try {
                // Wait a certain amount of time for tasks to complete
                if (!service.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                    service.shutdownNow(); // Forcefully terminate if tasks are not completed
                }
            } catch (InterruptedException e) {
                service.shutdownNow(); // Forcefully terminate if interrupted
                Thread.currentThread().interrupt(); // Restore interrupted status
                Log.e(TAG, "Executor service termination interrupted", e);
            }
        }

        // Shutdown scheduler if it is running
        shutdownScheduler();
        Log.i(TAG, "VPN stopped successfully");
    }
    private void shutdownScheduler() {
        if (scheduler != null && !scheduler.isShutdown()) {
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
                Log.e(TAG, "Scheduler termination interrupted", e);
            }
        }
    }

    private void publishConnectionState(ConnectionState state) {
        if (!connectionStateObservers.isEmpty()) {
            for (String observerKey : connectionStateObservers.keySet())
                publishConnectionStateTo(observerKey, state);
        }
    }

    private void publishConnectionStateTo(String observerKey, ConnectionState state) {
        Log.i("Publisher", "Publishing state " + state + " to " + observerKey);
        Messenger observer = connectionStateObservers.get(observerKey);
        if (observer == null) return;
        Bundle args = new Bundle();
        args.putString("state", state.toString());
        Message replyMsg = Message.obtain(null, MSG_TILE_STATE_SUBSCRIPTION_RESULT);
        replyMsg.setData(args);
        try {
            observer.send(replyMsg);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    private void setLastKnownState(ConnectionState lastKnownState) {
        this.lastKnownState = lastKnownState;
        publishConnectionState(lastKnownState);
    }

    private String getNotificationText() {
        boolean usePsiphon = fileManager.getBoolean("USERSETTING_psiphon");
        boolean useWarp = fileManager.getBoolean("USERSETTING_gool");

        if (usePsiphon) {
            return "Psiphon in Warp";
        } else if (useWarp) {
            return "Warp in Warp";
        }
        return "Warp";
    }

    private void createNotification() {
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
        NotificationChannelCompat notificationChannel = new NotificationChannelCompat.Builder(
                "vpn_service", NotificationManagerCompat.IMPORTANCE_DEFAULT)
                .setName("Vpn Service")
                .build();
        notificationManager.createNotificationChannel(notificationChannel);
        Intent disconnectIntent = new Intent(this, OblivionVpnService.class);
        disconnectIntent.setAction(OblivionVpnService.FLAG_VPN_STOP);
        PendingIntent disconnectPendingIntent = PendingIntent.getService(
                this, 0, disconnectIntent, PendingIntent.FLAG_IMMUTABLE);
        PendingIntent contentPendingIntent = PendingIntent.getActivity(
                this, 2, new Intent(this, MainActivity.class), PendingIntent.FLAG_IMMUTABLE);
        notification = new NotificationCompat.Builder(this, notificationChannel.getId())
                .setContentTitle("Vpn Service")
                .setContentText("Oblivion - " + getNotificationText())
                .setSmallIcon(R.mipmap.ic_notification)
                .setOnlyAlertOnce(true)
                .setOngoing(true)
                .setAutoCancel(true)
                .setShowWhen(false)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setDefaults(NotificationCompat.FLAG_ONLY_ALERT_ONCE)
                .setContentIntent(contentPendingIntent)
                .addAction(0, "Disconnect", disconnectPendingIntent)
                .build();
    }

    public void addConnectionStateObserver(String key, Messenger messenger) {
        connectionStateObservers.put(key, messenger);
    }

    public void removeConnectionStateObserver(String key) {
        connectionStateObservers.remove(key);
    }

    private void configure() throws Exception {
        VpnService.Builder builder = new VpnService.Builder();

        builder.setSession("oblivion")
            .setMtu(1500)
            .addAddress(PRIVATE_VLAN4_CLIENT, 30)
            .addAddress(PRIVATE_VLAN6_CLIENT, 126)
            .addDnsServer("1.1.1.1")
            .addDnsServer("1.0.0.1")
            .addDisallowedApplication(getPackageName())
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0);

        fileManager.getStringSet("splitTunnelApps", new HashSet<>());
        SplitTunnelMode splitTunnelMode = SplitTunnelMode.getSplitTunnelMode(fileManager);
        if (splitTunnelMode == SplitTunnelMode.BLACKLIST) {
            for (String packageName : getSplitTunnelApps()) {
                try {
                    builder.addDisallowedApplication(packageName);
                } catch (PackageManager.NameNotFoundException e) {
                    e.printStackTrace();
                }
            }
        }

        mInterface = builder.establish();
        if (mInterface == null) throw new RuntimeException("failed to establish VPN interface");
        Log.i(TAG, "Interface created");

        String endpoint = fileManager.getString("USERSETTING_endpoint", "engage.cloudflareclient.com:2408").trim();
        if (endpoint.equals("engage.cloudflareclient.com:2408")) {
            endpoint = "";
        }

        String license = fileManager.getString("USERSETTING_license", "").trim();
        boolean enablePsiphon = fileManager.getBoolean("USERSETTING_psiphon", false);
        String country = fileManager.getString("USERSETTING_country", "AT").trim();
        boolean enableGool = fileManager.getBoolean("USERSETTING_gool", false);

        StartOptions so = new StartOptions();
        so.setPath(getApplicationContext().getFilesDir().getAbsolutePath());
        so.setVerbose(true);
        so.setEndpoint(endpoint);
        so.setBindAddress(bindAddress);
        so.setLicense(license);
        so.setDNS("1.1.1.1");

        if (enablePsiphon && !enableGool) {
            so.setPsiphonEnabled(true);
            so.setCountry(country);
        }

        if (!enablePsiphon && enableGool) {
            so.setGool(true);
        }

        so.setTunFd(mInterface.getFd());

        Tun2socks.start(so);
    }

    private static class IncomingHandler extends Handler {
        private final WeakReference<OblivionVpnService> serviceRef;

        IncomingHandler(OblivionVpnService service) {
            serviceRef = new WeakReference<>(service);
        }

        @Override
        public void handleMessage(@NonNull Message msg) {
            final Message message = new Message();
            message.copyFrom(msg);
            OblivionVpnService service = serviceRef.get();
            if (service == null) return;
            switch (msg.what) {
                case MSG_CONNECTION_STATE_SUBSCRIBE: {
                    String key = message.getData().getString("key");
                    if (key == null)
                        throw new RuntimeException("No key was provided for the connection state observer");
                    if (service.connectionStateObservers.containsKey(key)) {
                        //Already subscribed
                        return;
                    }
                    service.addConnectionStateObserver(key, message.replyTo);
                    service.publishConnectionStateTo(key, service.lastKnownState);
                    break;
                }
                case MSG_CONNECTION_STATE_UNSUBSCRIBE: {
                    String key = message.getData().getString("key");
                    if (key == null)
                        throw new RuntimeException("No observer was specified to unregister");
                    service.removeConnectionStateObserver(key);
                    break;
                }
                default: {
                    super.handleMessage(msg);
                }
            }
        }
    }
}
