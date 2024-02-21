package org.bepass.oblivion;

public enum ConnectionState {
    CONNECTING, CONNECTED, DISCONNECTED;

    public boolean isDisconnected() {
        return this == DISCONNECTED;
    }
}
