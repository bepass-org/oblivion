package org.bepass.oblivion.enums;

import org.bepass.oblivion.config.AppConfigManager;

public enum SplitTunnelMode {
    DISABLED,
    BLACKLIST;

    public static SplitTunnelMode getSplitTunnelMode() {
        return AppConfigManager.getSplitTunnelMode();
    }
}
