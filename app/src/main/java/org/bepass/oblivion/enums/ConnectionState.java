package org.bepass.oblivion.enums;

public enum ConnectionState {
    CONNECTING, CONNECTED, DISCONNECTED;

    public boolean isDisconnected() {
        return this == DISCONNECTED;
    }
    public boolean isConnecting(){
        return this == CONNECTING;
    }
}
