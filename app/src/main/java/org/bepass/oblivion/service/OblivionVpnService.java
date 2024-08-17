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
import android.os.Looper;
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
import org.bepass.oblivion.enums.ConnectionState;
import org.bepass.oblivion.interfaces.ConnectionStateChangeListener;
import org.bepass.oblivion.R;
import org.bepass.oblivion.enums.SplitTunnelMode;
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
import java.util.List;
import java.util.Locale;
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
    private static final Map<String, Messenger> connectionStateObservers = new HashMap<>();
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
            // Adding jitter to avoid exact timing
            long jitter = (long) (Math.random() * 500); // Random delay between 0 to 500ms
            handler.postDelayed(this, 2000 + jitter); // Poll every ~2 seconds with some jitter
        }
    };
    // For JNI Calling in a new threa
    private static final Executor executorService = Executors.newSingleThreadExecutor();
    // For PingHTTPTestConnection to don't busy-waiting
    private static ScheduledExecutorService scheduler;
    private Notification notification;
    private static ParcelFileDescriptor mInterface;
    private String bindAddress;
    private static PowerManager.WakeLock wLock;
    private static ConnectionState lastKnownState = ConnectionState.DISCONNECTED;
    public static synchronized void startVpnService(Context context) {
        Intent intent = new Intent(context, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_START);
        context.startService(intent);
    }

    public static synchronized void stopVpnService(Context context) {
        Intent intent = new Intent(context, OblivionVpnService.class);
        intent.setAction(OblivionVpnService.FLAG_VPN_STOP);
        context.startService(intent);

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

        try {
            // Check if the host part is an IPv6 address (enclosed in square brackets)
            if (hostPort.startsWith("[")) {
                int closingBracketIndex = hostPort.indexOf(']');
                if (closingBracketIndex > 0) {
                    host = hostPort.substring(1, closingBracketIndex);
                    if (hostPort.length() > closingBracketIndex + 1 && hostPort.charAt(closingBracketIndex + 1) == ':') {
                        // There's a port number after the closing bracket
                        String portStr = hostPort.substring(closingBracketIndex + 2);
                        if (!portStr.isEmpty()) {
                            port = Integer.parseInt(portStr);
                        }
                    }
                } else {
                    throw new IllegalArgumentException("Invalid IPv6 address format");
                }
            } else {
                // Handle IPv4 or hostname (split at the last colon)
                int lastColonIndex = hostPort.lastIndexOf(':');
                if (lastColonIndex > 0) {
                    host = hostPort.substring(0, lastColonIndex);
                    String portStr = hostPort.substring(lastColonIndex + 1);
                    if (!portStr.isEmpty()) {
                        port = Integer.parseInt(portStr);
                    }
                } else {
                    host = hostPort; // No port specified
                }
            }
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid port number format in: " + hostPort, e);
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
        if (socksPort == -1) {
            return "false"; // Consider no port specified as not in use
        }
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
        return FileManager.getStringSet("splitTunnelApps", new HashSet<>());
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
        String port = FileManager.getString("USERSETTING_port");
        boolean enableLan = FileManager.getBoolean("USERSETTING_lan");
        String bindAddress = "127.0.0.1:" + port;

        if (isLocalPortInUse(bindAddress).equals("true")) {
            port = String.valueOf(findFreePort());
        }
        String bind = "127.0.0.1:" + port;
        if (enableLan) {
            bind = "0.0.0.0:" + port;
        }
        return bind;
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
        if (lastKnownState != ConnectionState.DISCONNECTED) {
            onRevoke();
        }
        setLastKnownState(ConnectionState.CONNECTING);
        Log.i(TAG, "Clearing Logs");
        clearLogFile();
        Log.i(TAG, "Create Notification");

        if (wLock == null) {
            wLock = ((PowerManager) getSystemService(Context.POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "oblivion:vpn");
            wLock.setReferenceCounted(false);
            wLock.acquire(3 * 60 * 1000L /*3 minutes*/);
        }

        executorService.execute(() -> {
            bindAddress = getBindAddress();
            Log.i(TAG, "Configuring VPN service");
            try {
                createNotification();
                if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.TIRAMISU) {
                    startForeground(1, notification);
                } else {
                    startForeground(1, notification, FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED);
                }
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
                createNotification();
                startForeground(1, notification);
            });
        });
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent != null ? intent.getAction() : null;

        if (FLAG_VPN_START.equals(action)) {
            // Start VPN
            if (lastKnownState == ConnectionState.DISCONNECTED) {
                start();
            }
        } else if (FLAG_VPN_STOP.equals(action)) {
            // Stop VPN
            onRevoke();
        }

        return START_STICKY;
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
        // Set the last known state to DISCONNECTED
        setLastKnownState(ConnectionState.DISCONNECTED);

        // Stop the foreground service
        stopForegroundService();
        Log.e(TAG, "VPN service is being forcefully stopped");

        // Release the wake lock if held
        if (wLock != null && wLock.isHeld()) {
            wLock.release();
            wLock = null;
            Log.e(TAG, "Wake lock released");
        } else {
            Log.w(TAG, "No wake lock to release");
        }

        // Close the VPN interface
        try {
            if (!FileManager.getBoolean("USERSETTING_proxymode")) {
                if (mInterface != null) {
                    mInterface.close();
                    mInterface = null; // Set to null to ensure it's not reused
                    Log.e(TAG, "VPN interface closed successfully");
                } else {
                    Log.w(TAG, "VPN interface was already null");
                }
            } else {
                Log.w(TAG, "Proxy mode is enabled; skipping VPN interface closure");
            }
        } catch (IOException e) {
            Log.e(TAG, "Critical error closing the VPN interface", e);
        }

        // Stop Tun2socks
        try {
            Tun2socks.stop();
            Log.e(TAG, "Tun2socks stopped successfully");
        } catch (Exception e) {
            Log.e(TAG, "Critical error stopping Tun2socks", e);
        }
        stopForegroundService();
        stopSelf();
        // Shutdown executor service
        if (executorService instanceof ExecutorService) {
            ExecutorService service = (ExecutorService) executorService;
            try {
                service.shutdownNow(); // Attempt to forcibly shutdown
                if (!service.awaitTermination(300, TimeUnit.MILLISECONDS)) {
                    Log.e(TAG, "ExecutorService did not terminate in the specified time");
                    List<Runnable> droppedTasks = service.shutdownNow();
                    Log.e(TAG, "ExecutorService was forcibly shut down. Dropped tasks: " + droppedTasks);
                }
                Log.e(TAG, "ExecutorService shut down successfully");
            } catch (InterruptedException ie) {
                Log.e(TAG, "Interrupted during ExecutorService shutdown", ie);
                Thread.currentThread().interrupt();
            }
        } else {
            Log.w(TAG, "ExecutorService was not an instance of ExecutorService");
        }

        Log.e(TAG, "VPN stopped successfully or encountered errors. Check logs for details.");
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
        OblivionVpnService.lastKnownState = lastKnownState;
        publishConnectionState(lastKnownState);
        createNotification();
        startForeground(1, notification);
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

        String notificationTitle = getNotificationTitle();
        String notificationContent = getNotificationContent();

        notification = new NotificationCompat.Builder(this, notificationChannel.getId())
                .setContentTitle(notificationTitle)
                .setContentText(notificationContent)
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

    private String getNotificationTitle() {
        switch (lastKnownState) {
            case CONNECTING:
                return "Oblivion - Connecting";
            case CONNECTED:
                return "Oblivion - Connected";
            case DISCONNECTED:
                return "Oblivion - Disconnected";
            default:
                return "Oblivion";
        }
    }

    private String getNotificationContent() {
        boolean usePsiphon = FileManager.getBoolean("USERSETTING_psiphon");
        boolean useWarp = FileManager.getBoolean("USERSETTING_gool");
        boolean proxyMode = FileManager.getBoolean("USERSETTING_proxymode");
        String portInUse = FileManager.getString("USERSETTING_port");

        StringBuilder content = new StringBuilder();

        if (proxyMode) {
            content.append("Proxy Mode - ");
        } else {
            content.append("VPN Mode - ");
        }

        if (usePsiphon) {
            content.append("Psiphon in Warp");
        } else if (useWarp) {
            content.append("Warp in Warp");
        } else {
            content.append("Warp");
        }

        if (proxyMode) {
            content.append(String.format(Locale.getDefault(), " (SOCKS5 127.0.0.1:%s)", portInUse));
        }

        return content.toString();
    }

    public void addConnectionStateObserver(String key, Messenger messenger) {
        connectionStateObservers.put(key, messenger);
    }

    public void removeConnectionStateObserver(String key) {
        connectionStateObservers.remove(key);
    }

    private void configure() throws Exception {
        boolean proxyModeEnabled = FileManager.getBoolean("USERSETTING_proxymode");
        if (proxyModeEnabled) {
            // Proxy mode logic
            StartOptions so = new StartOptions();
            so.setPath(getApplicationContext().getFilesDir().getAbsolutePath());
            so.setVerbose(true);
            so.setEndpoint(getEndpoint());
            so.setBindAddress(bindAddress);
            so.setLicense(FileManager.getString("USERSETTING_license", "").trim());
            so.setDNS("1.1.1.1");
            so.setEndpointType(FileManager.getInt("USERSETTING_endpoint_type"));

            if (FileManager.getBoolean("USERSETTING_psiphon", false)) {
                so.setPsiphonEnabled(true);
                so.setCountry(FileManager.getString("USERSETTING_country", "AT").trim());
            } else if (FileManager.getBoolean("USERSETTING_gool", false)) {
                so.setGool(true);
            }

            // Start tun2socks in proxy mode
            Tun2socks.start(so);

        } else {
            // VPN mode logic
            VpnService.Builder builder = new VpnService.Builder();
            configureVpnBuilder(builder);

            mInterface = builder.establish();
            if (mInterface == null) throw new RuntimeException("failed to establish VPN interface");
            Log.i(TAG, "Interface created");

            StartOptions so = new StartOptions();
            so.setPath(getApplicationContext().getFilesDir().getAbsolutePath());
            so.setVerbose(true);
            so.setEndpoint(getEndpoint());
            so.setBindAddress(bindAddress);
            so.setLicense(FileManager.getString("USERSETTING_license", "").trim());
            so.setDNS("1.1.1.1");
            so.setEndpointType(FileManager.getInt("USERSETTING_endpoint_type"));
            so.setTunFd(mInterface.getFd());

            if (FileManager.getBoolean("USERSETTING_psiphon", false)) {
                so.setPsiphonEnabled(true);
                so.setCountry(FileManager.getString("USERSETTING_country", "AT").trim());
            } else if (FileManager.getBoolean("USERSETTING_gool", false)) {
                so.setGool(true);
            }

            // Start tun2socks with VPN
            Tun2socks.start(so);
        }
    }

    private void configureVpnBuilder(VpnService.Builder builder) throws Exception {
        builder.setSession("oblivion")
                .setMtu(1500)
                .addAddress(PRIVATE_VLAN4_CLIENT, 30)
                .addAddress(PRIVATE_VLAN6_CLIENT, 126)
                .addDnsServer("1.1.1.1")
                .addDnsServer("1.0.0.1")
                .addDisallowedApplication(getPackageName())
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0);

        // Determine split tunnel mode
        SplitTunnelMode splitTunnelMode = SplitTunnelMode.getSplitTunnelMode();
        if (splitTunnelMode == SplitTunnelMode.BLACKLIST) {
            Set<String> splitTunnelApps = getSplitTunnelApps();
            for (String packageName : splitTunnelApps) {
                try {
                    builder.addDisallowedApplication(packageName);
                } catch (PackageManager.NameNotFoundException ignored) {
                }
            }
        }
    }

    private String getEndpoint() {
        String endpoint = FileManager.getString("USERSETTING_endpoint", "engage.cloudflareclient.com:2408").trim();
        return endpoint.equals("engage.cloudflareclient.com:2408") ? "" : endpoint;
    }

    private static class IncomingHandler extends Handler {
        private final WeakReference<OblivionVpnService> serviceRef;

        IncomingHandler(OblivionVpnService service) {
            super(Looper.getMainLooper()); // Ensure the handler runs on the main thread
            serviceRef = new WeakReference<>(service);
        }

        @Override
        public void handleMessage(@NonNull Message msg) {
            OblivionVpnService service = serviceRef.get();
            if (service == null) return;

            switch (msg.what) {
                case MSG_CONNECTION_STATE_SUBSCRIBE: {
                    String key = msg.getData().getString("key");
                    if (key == null) {
                        Log.e("IncomingHandler", "No key was provided for the connection state observer");
                        return;
                    }
                    if (connectionStateObservers.containsKey(key)) {
                        // Already subscribed
                        return;
                    }
                    service.addConnectionStateObserver(key, msg.replyTo);
                    service.publishConnectionStateTo(key, lastKnownState);
                    break;
                }
                case MSG_CONNECTION_STATE_UNSUBSCRIBE: {
                    String key = msg.getData().getString("key");
                    if (key == null) {
                        Log.e("IncomingHandler", "No observer was specified to unregister");
                        return;
                    }
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
