package org.bepass.oblivion;

import org.bepass.oblivion.enums.ConnectionState;

public interface ConnectionStateChangeListener {
    void onChange(ConnectionState state);
}
