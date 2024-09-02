package org.bepass.oblivion.config;

import static androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_NO;

import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;

import androidx.appcompat.app.AppCompatDelegate;

import org.bepass.oblivion.enums.SplitTunnelMode;
import org.bepass.oblivion.utils.CountryCode;

import java.util.Collections;
import java.util.Set;

public class AppConfigManager {

    private static SharedPreferences userDataPreferences = null;

    public static void init(Application application) {
        userDataPreferences = application.getSharedPreferences(KeyConstant.FILE_NAME, Context.MODE_PRIVATE);
    }

    public static void setSplitTunnelMode(SplitTunnelMode mode) {
        userDataPreferences.edit().putString(KeyConstant.SPLIT_TUNNEL_MODE, mode.toString()).apply();
    }

    public static SplitTunnelMode getSplitTunnelMode() {
        String mode = userDataPreferences.getString(KeyConstant.SPLIT_TUNNEL_MODE, "");
        return mode.isEmpty() ? SplitTunnelMode.DISABLED : SplitTunnelMode.valueOf(mode);
    }

    public static void setSettingEndPoint(EndPoint endPoint) {
        userDataPreferences.edit().putString(KeyConstant.SETTINGS_ENDPOINT, endPoint.getValue()).apply();
    }

    public static EndPoint getSettingEndPoint() {
        String endPoint = userDataPreferences.getString(KeyConstant.SETTINGS_ENDPOINT, "engage.cloudflareclient.com:2408");
        return new EndPoint(endPoint);
    }

    public static void setSettingCountry(CountryCode countryCode) {
        userDataPreferences.edit().putString(KeyConstant.SETTINGS_COUNTRY, countryCode.getValue()).apply();
    }

    public static CountryCode getSettingCountry() {
        String countryCode = userDataPreferences.getString(KeyConstant.SETTINGS_COUNTRY, "AU");
        return new CountryCode(countryCode);
    }

    public static void setRawString(String key, String value) {
        userDataPreferences.edit().putString(key, value).apply();
    }

    public static String getRawString(String key, String defValue) {
        return userDataPreferences.getString(key, defValue);
    }

    public static void setSettingPort(PortNumber portNumber) {
        userDataPreferences.edit().putString(KeyConstant.SETTINGS_PORT, portNumber.getValue()).apply();
    }

    public static PortNumber getSettingPort() {
        String portNumber = userDataPreferences.getString(KeyConstant.SETTINGS_PORT, "8086");
        return new PortNumber(portNumber);
    }

    public static void setSettingLan(boolean checked) {
        userDataPreferences.edit().putBoolean(KeyConstant.SETTINGS_LAN, checked).apply();
    }

    public static boolean getSettingLan() {
        return userDataPreferences.getBoolean(KeyConstant.SETTINGS_LAN, false);
    }

    public static void setSettingGool(boolean checked) {
        userDataPreferences.edit().putBoolean(KeyConstant.SETTINGS_GOOL, checked).apply();
    }

    public static boolean getSettingGool() {
        return userDataPreferences.getBoolean(KeyConstant.SETTINGS_GOOL, false);
    }

    public static void setSettingPsiphon(boolean checked) {
        userDataPreferences.edit().putBoolean(KeyConstant.SETTINGS_PSIPHON, checked).apply();
    }

    public static boolean getSettingPsiphon() {
        return userDataPreferences.getBoolean(KeyConstant.SETTINGS_PSIPHON, false);
    }

    public static void setSettingProxyMode(boolean checked) {
        userDataPreferences.edit().putBoolean(KeyConstant.SETTINGS_PROXY_MODE, checked).apply();
    }

    public static boolean getSettingProxyMode() {
        return userDataPreferences.getBoolean(KeyConstant.SETTINGS_PROXY_MODE, false);
    }

    public static void setRawBoolean(String key, boolean value) {
        userDataPreferences.edit().putBoolean(key, value).apply();
    }

    public static boolean getRawBoolean(String key, boolean defValue) {
        return userDataPreferences.getBoolean(key, defValue);
    }

    public static void setSplitTunnelApps(Set<String> appsPackageName) {
        userDataPreferences.edit().putStringSet(KeyConstant.SPLIT_TUNNEL_APPS, appsPackageName).apply();
    }

    public static Set<String> getSplitTunnelApps() {
        return userDataPreferences.getStringSet(KeyConstant.SPLIT_TUNNEL_APPS, Collections.emptySet());
    }

    public static void setSettingEndPointType(EndPointType type) {
        userDataPreferences.edit().putInt(KeyConstant.SETTINGS_ENDPOINT_TYPE, type.ordinal()).apply();
    }

    public static EndPointType getSettingEndPointType() {
        int endpointType = userDataPreferences.getInt(KeyConstant.SETTINGS_ENDPOINT_TYPE, 0);
        return EndPointType.values()[endpointType];
    }

    public static void setSettingCountryIndex(int index) {
        userDataPreferences.edit().putInt(KeyConstant.SETTINGS_COUNTRY_INDEX, index).apply();
    }

    public static int getSettingCountryIndex() {
        return userDataPreferences.getInt(KeyConstant.SETTINGS_COUNTRY_INDEX, 0);
    }

    public static void setSettingLicense(String value) {
        userDataPreferences.edit().putString(KeyConstant.SETTINGS_LICENSE, value).apply();
    }

    public static String getSettingLicense() {
        return userDataPreferences.getString(KeyConstant.SETTINGS_LICENSE, "");
    }

    public static void setSettingNightMode(@AppCompatDelegate.NightMode int mode) {
        userDataPreferences.edit().putInt(KeyConstant.SETTING_NIGHT_MODE, mode).apply();
    }

    public static int getSettingNightMode() {
        return userDataPreferences.getInt(KeyConstant.SETTING_NIGHT_MODE, MODE_NIGHT_NO);
    }

    public static void setSettingSavedEndPoints(Set<String> endPoints) {
        userDataPreferences.edit().putStringSet(KeyConstant.SETTING_SAVED_ENDPOINTS, endPoints).apply();
    }

    public static Set<String> getSettingSavedEndPoints() {
        return userDataPreferences.getStringSet(KeyConstant.SETTING_SAVED_ENDPOINTS, Collections.emptySet());
    }

    public static void resetToDefault() {
        userDataPreferences.edit().clear().apply();
    }

    private static class KeyConstant {
        public static final String FILE_NAME = "UserData";

        public static final String SPLIT_TUNNEL_MODE = "splitTunnelMode";
        public static final String SETTINGS_ENDPOINT = "USERSETTING_endpoint";
        public static final String SETTINGS_COUNTRY = "USERSETTING_country";
        public static final String SETTINGS_PORT = "USERSETTING_port";
        public static final String SETTINGS_LAN = "USERSETTING_lan";
        public static final String SETTINGS_GOOL = "USERSETTING_gool";
        public static final String SETTINGS_PSIPHON = "USERSETTING_psiphon";
        public static final String SETTINGS_PROXY_MODE = "USERSETTING_proxymode";
        public static final String SPLIT_TUNNEL_APPS = "splitTunnelApps";
        public static final String SETTINGS_ENDPOINT_TYPE = "USERSETTING_endpoint_type";
        public static final String SETTINGS_COUNTRY_INDEX = "USERSETTING_country_index";
        public static final String SETTINGS_LICENSE = "USERSETTING_license";
        public static final String SETTING_NIGHT_MODE = "setting_dark_mode";
        public static final String SETTING_SAVED_ENDPOINTS = "saved_endpoints";
    }
}
