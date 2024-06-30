package org.bepass.oblivion.interfaces;

import org.bepass.oblivion.ConnectionState;

public interface ConnectionStateChangeListener {
    void onChange(ConnectionState state);
}
