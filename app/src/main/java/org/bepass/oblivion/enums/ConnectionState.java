package org.bepass.oblivion.enums;

public enum ConnectionState {
    CONNECTING,
    CONNECTED,
    DISCONNECTED;

    public boolean connectedOrConnecting() {
        return this == CONNECTED || this == CONNECTING;
    }
}
