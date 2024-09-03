package org.bepass.oblivion.enums;

public enum ConnectionState {
    CONNECTING, CONNECTED, DISCONNECTED, DISCONNECTING;

    public boolean isDisconnected() {
        return this == DISCONNECTED;
    }
}
