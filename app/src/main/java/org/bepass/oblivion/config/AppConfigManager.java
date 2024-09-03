package org.bepass.oblivion.config;

import static androidx.appcompat.app.AppCompatDelegate.MODE_NIGHT_NO;

import android.app.Application;

import androidx.appcompat.app.AppCompatDelegate;

import com.tencent.mmkv.MMKV;

import org.bepass.oblivion.enums.SplitTunnelMode;
import org.bepass.oblivion.utils.CountryCode;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class AppConfigManager {

    private static MMKV mmkv;

    public static void init(Application application) {
        MMKV.initialize(application.getApplicationContext());
        mmkv = MMKV.mmkvWithID(KeyConstant.FILE_NAME, MMKV.MULTI_PROCESS_MODE);
    }

    public static SplitTunnelMode getSplitTunnelMode() {
        String mode = mmkv.decodeString(KeyConstant.SPLIT_TUNNEL_MODE, "");
        return mode == null || mode.isEmpty() ? SplitTunnelMode.DISABLED : SplitTunnelMode.valueOf(mode);
    }

    public static void setSplitTunnelMode(SplitTunnelMode mode) {
        mmkv.encode(KeyConstant.SPLIT_TUNNEL_MODE, mode.toString());
    }

    public static EndPoint getSettingEndPoint() {
        String endPoint = mmkv.decodeString(KeyConstant.SETTINGS_ENDPOINT, "engage.cloudflareclient.com:2408");
        return new EndPoint(endPoint);
    }

    public static void setSettingEndPoint(EndPoint endPoint) {
        mmkv.encode(KeyConstant.SETTINGS_ENDPOINT, endPoint.getValue());
    }

    public static CountryCode getSettingCountry() {
        String countryCode = mmkv.decodeString(KeyConstant.SETTINGS_COUNTRY, "AU");
        return new CountryCode(countryCode);
    }

    public static void setSettingCountry(CountryCode countryCode) {
        mmkv.encode(KeyConstant.SETTINGS_COUNTRY, countryCode.getValue());
    }

    public static PortNumber getSettingPort() {
        String portNumber = mmkv.decodeString(KeyConstant.SETTINGS_PORT, "8086");
        return new PortNumber(portNumber);
    }

    public static void setSettingPort(PortNumber portNumber) {
        mmkv.encode(KeyConstant.SETTINGS_PORT, portNumber.getValue());
    }

    public static boolean getSettingLan() {
        return mmkv.decodeBool(KeyConstant.SETTINGS_LAN, false);
    }

    public static void setSettingLan(boolean checked) {
        mmkv.encode(KeyConstant.SETTINGS_LAN, checked);
    }

    public static boolean getSettingGool() {
        return mmkv.decodeBool(KeyConstant.SETTINGS_GOOL, false);
    }

    public static void setSettingGool(boolean checked) {
        mmkv.encode(KeyConstant.SETTINGS_GOOL, checked);
    }

    public static boolean getSettingPsiphon() {
        return mmkv.decodeBool(KeyConstant.SETTINGS_PSIPHON, false);
    }

    public static void setSettingPsiphon(boolean checked) {
        mmkv.encode(KeyConstant.SETTINGS_PSIPHON, checked);
    }

    public static boolean getSettingProxyMode() {
        return mmkv.decodeBool(KeyConstant.SETTINGS_PROXY_MODE, false);
    }

    public static void setSettingProxyMode(boolean checked) {
        mmkv.encode(KeyConstant.SETTINGS_PROXY_MODE, checked);
    }

    public static void setRawBoolean(String key, boolean value) {
        mmkv.encode(key, value);
    }

    public static boolean getRawBoolean(String key, boolean defValue) {
        return mmkv.decodeBool(key, defValue);
    }

    public static Set<String> getSplitTunnelApps() {
        return mmkv.decodeStringSet(KeyConstant.SPLIT_TUNNEL_APPS, Collections.emptySet());
    }

    public static void setSplitTunnelApps(Set<String> appsPackageName) {
        mmkv.encode(KeyConstant.SPLIT_TUNNEL_APPS, appsPackageName);
    }

    public static EndPointType getSettingEndPointType() {
        int endpointType = mmkv.decodeInt(KeyConstant.SETTINGS_ENDPOINT_TYPE, 0);
        return EndPointType.values()[endpointType];
    }

    public static void setSettingEndPointType(EndPointType type) {
        mmkv.encode(KeyConstant.SETTINGS_ENDPOINT_TYPE, type.ordinal());
    }

    public static int getSettingCountryIndex() {
        return mmkv.decodeInt(KeyConstant.SETTINGS_COUNTRY_INDEX, 0);
    }

    public static void setSettingCountryIndex(int index) {
        mmkv.encode(KeyConstant.SETTINGS_COUNTRY_INDEX, index);
    }

    public static String getSettingLicense() {
        return mmkv.decodeString(KeyConstant.SETTINGS_LICENSE, "");
    }

    public static void setSettingLicense(String value) {
        mmkv.encode(KeyConstant.SETTINGS_LICENSE, value);
    }

    public static int getSettingNightMode() {
        return mmkv.decodeInt(KeyConstant.SETTING_NIGHT_MODE, MODE_NIGHT_NO);
    }

    public static void setSettingNightMode(@AppCompatDelegate.NightMode int mode) {
        mmkv.encode(KeyConstant.SETTING_NIGHT_MODE, mode);
    }

    public static void insertToSettingSavedEndPointsWithTitle(String title, String endPoint) {
        Set<String> updatedEndPoints = new HashSet<>(getSettingSavedEndPointsWithTitle());
        updatedEndPoints.add(title + "," + endPoint);
        mmkv.encode(KeyConstant.SETTING_SAVED_ENDPOINTS, updatedEndPoints);
    }

    public static Set<String> getSettingSavedEndPointsWithTitle() {
        return mmkv.decodeStringSet(KeyConstant.SETTING_SAVED_ENDPOINTS, Collections.emptySet());
    }

    public static void resetToDefault() {
        mmkv.clearAllWithKeepingSpace();
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
