package org.bepass.oblivion.widget;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.widget.RemoteViews;

import androidx.core.content.ContextCompat;

import org.bepass.oblivion.R;
import org.bepass.oblivion.service.OblivionVpnService;
import org.bepass.oblivion.utils.FileManager;

public class OblivionWidgetProvider extends AppWidgetProvider {
    public static final String ACTION_TOGGLE = "org.bepass.oblivion.widget.TOGGLE";

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = buildViews(context);
            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        if (intent != null && ACTION_TOGGLE.equals(intent.getAction())) {
            FileManager.initialize(context);
            String state = FileManager.getString("lastKnownState", "DISCONNECTED");
            if ("CONNECTED".equals(state) || "CONNECTING".equals(state)) {
                Intent stopIntent = new Intent(context, OblivionVpnService.class);
                stopIntent.setAction(OblivionVpnService.FLAG_VPN_STOP);
                ContextCompat.startForegroundService(context, stopIntent);
            } else {
                Intent startIntent = new Intent(context, OblivionVpnService.class);
                startIntent.setAction(OblivionVpnService.FLAG_VPN_START);
                startIntent.putExtra("USERSETTING_proxymode", FileManager.getBoolean("USERSETTING_proxymode"));
                startIntent.putExtra("USERSETTING_license", FileManager.getString("USERSETTING_license"));
                startIntent.putExtra("USERSETTING_endpoint_type", FileManager.getInt("USERSETTING_endpoint_type"));
                startIntent.putExtra("USERSETTING_psiphon", FileManager.getBoolean("USERSETTING_psiphon"));
                startIntent.putExtra("USERSETTING_country", FileManager.getString("USERSETTING_country"));
                startIntent.putExtra("USERSETTING_gool", FileManager.getBoolean("USERSETTING_gool"));
                startIntent.putExtra("USERSETTING_endpoint", FileManager.getString("USERSETTING_endpoint"));
                startIntent.putExtra("USERSETTING_port", FileManager.getString("USERSETTING_port"));
                startIntent.putExtra("USERSETTING_lan", FileManager.getBoolean("USERSETTING_lan"));
                startIntent.putExtra("USERSETTING_bind_host", FileManager.getString("USERSETTING_bind_host"));
                startIntent.putExtra("USERSETTING_dns_primary", FileManager.getString("USERSETTING_dns_primary", "1.1.1.1"));
                startIntent.putExtra("USERSETTING_dns_secondary", FileManager.getString("USERSETTING_dns_secondary", "1.0.0.1"));
                startIntent.putExtra("USERSETTING_mtu", FileManager.getInt("USERSETTING_mtu"));
                startIntent.putExtra("USERSETTING_bypass_lan", FileManager.getBoolean("USERSETTING_bypass_lan"));
                startIntent.putExtra("USERSETTING_keepAwake", FileManager.getBoolean("USERSETTING_keepAwake"));
                startIntent.putExtra("USERSETTING_ipv6", FileManager.getBoolean("USERSETTING_ipv6"));
                ContextCompat.startForegroundService(context, startIntent);
            }
            AppWidgetManager mgr = AppWidgetManager.getInstance(context);
            int[] ids = mgr.getAppWidgetIds(new ComponentName(context, OblivionWidgetProvider.class));
            onUpdate(context, mgr, ids);
        }
    }

    private RemoteViews buildViews(Context context) {
        FileManager.initialize(context);
        String state = FileManager.getString("lastKnownState", "DISCONNECTED");
        int statusRes = R.string.notConnected;
        boolean connected = false;
        if ("CONNECTED".equals(state)) { statusRes = R.string.connected; connected = true; }
        else if ("CONNECTING".equals(state)) { statusRes = R.string.connecting; }

        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_oblivion);
        views.setTextViewText(R.id.widget_status, context.getString(statusRes));
        views.setTextViewText(R.id.widget_title, context.getString(R.string.app_name));
        views.setTextViewText(R.id.widget_toggle, context.getString(connected ? R.string.widget_disconnect : R.string.widget_connect));

        Intent toggleIntent = new Intent(context, OblivionWidgetProvider.class);
        toggleIntent.setAction(ACTION_TOGGLE);
        PendingIntent pi = PendingIntent.getBroadcast(context, 0, toggleIntent, PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.widget_toggle, pi);
        return views;
    }
}
