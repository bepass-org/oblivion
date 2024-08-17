package org.bepass.oblivion.enums;

import org.bepass.oblivion.utils.FileManager;

public enum SplitTunnelMode {
    DISABLED,
    BLACKLIST,
    PERMITTEDLIST;

    public static SplitTunnelMode getSplitTunnelMode() {
        SplitTunnelMode splitTunnelMode;
        try {
            splitTunnelMode = SplitTunnelMode.valueOf(FileManager.getString("splitTunnelMode", SplitTunnelMode.DISABLED.toString()));
        } catch (Exception e) {
            splitTunnelMode = SplitTunnelMode.DISABLED;
        }
        return splitTunnelMode;
    }
}
