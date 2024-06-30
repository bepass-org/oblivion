package org.bepass.oblivion.interfaces;

import org.bepass.oblivion.enums.ConnectionState;

public interface ConnectionStateChangeListener {
    void onChange(ConnectionState state);
}
