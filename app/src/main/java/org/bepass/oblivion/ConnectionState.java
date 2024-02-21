package org.bepass.oblivion;

public enum ConnectionState {
    CONNECTING, CONNECTED, DISCONNECTED;

    public boolean isConnectedOrConnecting() {
        return this == CONNECTED || this == CONNECTING;
    }
}
