package org.bepass.oblivion.enums;

import org.bepass.oblivion.FileManager;

public enum SplitTunnelMode {
    DISABLED,
    BLACKLIST;

    public static SplitTunnelMode getSplitTunnelMode(FileManager fm) {
        SplitTunnelMode splitTunnelMode;
        try {
            splitTunnelMode = SplitTunnelMode.valueOf(fm.getString("splitTunnelMode", SplitTunnelMode.DISABLED.toString()));
        } catch (Exception e) {
            splitTunnelMode = SplitTunnelMode.DISABLED;
        }
        return splitTunnelMode;
    }

}
