package org.bepass.oblivion;

import android.content.Context;
import android.os.Handler;

import com.vdurmont.emoji.EmojiManager;

import org.json.JSONObject;

import java.net.InetSocketAddress;
import java.net.Proxy;
import java.util.Locale;
import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;


public class PublicIPUtils {

    private static PublicIPUtils instance;
    private final FileManager fm;
    ExecutorService executorService = Executors.newFixedThreadPool(1);

    public PublicIPUtils(Context context) {
        fm = FileManager.getInstance(context);
    }

    // Public method to get the singleton instance
    public static synchronized PublicIPUtils getInstance(Context context) {
        if (instance == null) {
            instance = new PublicIPUtils(context.getApplicationContext());
        }
        return instance;
    }


    public void getIPDetails(IPDetailsCallback callback) {
        Handler handler = new Handler();
        IPDetails details = new IPDetails();
        executorService.execute(() -> {
            long startTime = System.currentTimeMillis();
            while (System.currentTimeMillis() - startTime < 30 * 1000) { // 30 seconds
                try {
                    int socksPort = Integer.parseInt(fm.getString("USERSETTING_port"));
                    Proxy proxy = new Proxy(Proxy.Type.SOCKS, new InetSocketAddress("localhost", socksPort));
                    OkHttpClient client = new OkHttpClient.Builder()
                            .proxy(proxy)
                            .connectTimeout(5, TimeUnit.SECONDS) // 5 seconds connection timeout
                            .readTimeout(5, TimeUnit.SECONDS) // 5 seconds read timeout
                            .build();
                    Request request = new Request.Builder()
                            .url("https://api.country.is/")
                            .build();
                    JSONObject jsonData;
                    try (Response response = client.newCall(request).execute()) {
                        jsonData = new JSONObject(Objects.requireNonNull(response.body()).string());
                    }
                    details.ip = jsonData.getString("ip");
                    details.country = jsonData.getString("country");
                    details.flag = EmojiManager.getForAlias(jsonData.getString("country").toLowerCase(Locale.ROOT)).getUnicode();
                    handler.post(() -> callback.onDetailsReceived(details));
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                }

                try {
                    Thread.sleep(1000); // Sleep before retrying
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    return;
                }
                handler.post(() -> callback.onDetailsReceived(details));
            }
        });
    }

    public interface IPDetailsCallback {
        void onDetailsReceived(IPDetails details);
    }
}
