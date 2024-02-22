package org.bepass.oblivion;

import android.os.Handler;
import android.util.Log;

import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.URL;

public class PublicIPUtils {

    public interface IPDetailsCallback {
        void onDetailsReceived(IPDetails details);
    }

    public static String convertStreamToString(InputStream is) {
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder sb = new StringBuilder();

        String line;
        try {
            while ((line = reader.readLine()) != null) {
                sb.append(line).append('\n');
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                is.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return sb.toString();
    }

    public static void getIPDetails(int port, IPDetailsCallback callback) {
        Handler handler = new Handler();
        new Thread(() -> {
            IPDetails details = new IPDetails();
            try {
                Proxy proxy = new Proxy(Proxy.Type.SOCKS, new InetSocketAddress("127.0.0.1", port));
                URL url = new URL("https://ipwho.is/");
                HttpURLConnection connection = (HttpURLConnection) url.openConnection(proxy);
                InputStream in = new BufferedInputStream(connection.getInputStream());
                String response = convertStreamToString(in);
                JSONObject jsonData = new JSONObject(response);
                JSONObject flag = jsonData.getJSONObject("flag");
                details.ip = jsonData.getString("ip");
                details.country = jsonData.getString("country");
                details.city = jsonData.getString("city");
                details.flag = flag.getString("emoji");
            } catch (Exception e) {
                Log.i("VPN", "Failed to get details", e);
            }
            handler.post(() -> callback.onDetailsReceived(details));
        }).start();
    }

}
