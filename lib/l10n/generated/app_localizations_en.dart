// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Oblivion';

  @override
  String get appDisplayName => 'Oblivion';

  @override
  String get appTagline => 'Internet for all, or no one';

  @override
  String get introMeaning => 'Means \"unawareness, ignorance\"';

  @override
  String get introCredit =>
      'Built through the efforts of #Yousef_Ghobadi and dozens of known and anonymous activists, so that free access to the internet belongs to everyone.';

  @override
  String get memorialTitle => 'In memory of those killed on 18 and 19 Dey';

  @override
  String get memorialBody =>
      'Unarmed people, shot dead by the forces of the Islamic Republic';

  @override
  String get memorialVow => 'We will not forgive, we will not forget';

  @override
  String get introSegaro => '#Segaro';

  @override
  String get introYousef => '#Yousef_Ghobadi';

  @override
  String get introContinue => 'Continue';

  @override
  String get stateDisconnected => 'Not connected';

  @override
  String get stateConnecting => 'Connecting';

  @override
  String get stateValidating => 'Validating tunnel';

  @override
  String get stateConnected => 'Connected';

  @override
  String get stateDisconnecting => 'Disconnecting';

  @override
  String get stateFailed => 'Connection failed';

  @override
  String get tapToConnect => 'Tap to connect';

  @override
  String get tapToDisconnect => 'Tap to disconnect';

  @override
  String get yourLocation => 'Your location';

  @override
  String get exitLocation => 'Exit location';

  @override
  String get detectingLocation => 'Detecting location';

  @override
  String get locationUnknown => 'Unknown';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get duration => 'Duration';

  @override
  String get protocol => 'Protocol';

  @override
  String get settings => 'Settings';

  @override
  String get logs => 'Logs';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get sectionCore => 'Core';

  @override
  String get sectionNetwork => 'Network';

  @override
  String get sectionAdvanced => 'Advanced';

  @override
  String get routingTunnelDescMobile =>
      'Routes all device traffic through the tunnel';

  @override
  String get tunnelDegraded =>
      'Only the local proxy is up, device traffic is not going through the tunnel';

  @override
  String get tunnelDegradedHint =>
      'Full tunnel mode needs the app to run with administrator rights';

  @override
  String get zeroTrust => 'Organization account';

  @override
  String get zeroTrustDesc =>
      'Connect with a Cloudflare Zero Trust account instead of a personal one';

  @override
  String get zeroTrustOff => 'Off';

  @override
  String get zeroTrustTeam => 'Team name';

  @override
  String get zeroTrustTeamDesc =>
      'The name in your <team>.cloudflareaccess.com address';

  @override
  String get zeroTrustToken => 'Login token';

  @override
  String get zeroTrustTokenDesc =>
      'Sign in at <team>.cloudflareaccess.com/warp in a browser and paste the token here';

  @override
  String get zeroTrustServiceToken => 'Service token';

  @override
  String get zeroTrustClientId => 'Client ID';

  @override
  String get zeroTrustClientSecret => 'Client secret';

  @override
  String get zeroTrustGateway =>
      'Send traffic through the organization gateway';

  @override
  String get zeroTrustGatewayDesc =>
      'The organization\'s filtering and logging apply. It adds a hop inside the tunnel and your browsing is recorded.';

  @override
  String get zeroTrustReady => 'Ready to connect';

  @override
  String get zeroTrustNeedsToken =>
      'Add an email address, a login token or a service token';

  @override
  String get zeroTrustSet => 'Set';

  @override
  String get zeroTrustClear => 'Clear the organization account';

  @override
  String get zeroTrustEmail => 'Email address';

  @override
  String get zeroTrustEmailDesc =>
      'The simplest way in. Cloudflare emails a one-time code when you connect, and the app asks you for it.';

  @override
  String get zeroTrustSignIn => 'How you sign in';

  @override
  String get zeroTrustCodeTitle => 'Login code';

  @override
  String zeroTrustCodeBody(String email) {
    return 'A code was emailed to $email. Enter it to finish signing in.';
  }

  @override
  String get zeroTrustCodeRetry =>
      'That code was not accepted. Check your mailbox and try again.';

  @override
  String get zeroTrustCodePlaceholder => 'Code from the email';

  @override
  String get zeroTrustCodeSend => 'Sign in';

  @override
  String get zeroTrustCodeLost => 'The core is no longer waiting for a code';

  @override
  String get notificationConnected => 'Tunnel active';

  @override
  String get notificationConnecting => 'Establishing tunnel';

  @override
  String get notificationDisconnect => 'Disconnect';

  @override
  String get sectionRules => 'Where traffic goes';

  @override
  String get advancedDesc => 'DNS, port, traffic rules and finer settings';

  @override
  String get ruleBlock => 'Blocked sites';

  @override
  String get ruleBlockDesc => 'These addresses are not allowed to open';

  @override
  String get ruleDirect => 'Skip the tunnel';

  @override
  String get ruleDirectDesc =>
      'These open through your own connection instead of the tunnel';

  @override
  String get ruleNone => 'Empty';

  @override
  String get ruleHint =>
      'One address per line. A site name, an IP address or a port number all work.';

  @override
  String get sectionApp => 'App';

  @override
  String get protocolMasque => 'MASQUE';

  @override
  String get protocolMasqueDesc =>
      'Modern QUIC/HTTP-3 transport, best on healthy networks';

  @override
  String get protocolWireGuard => 'WireGuard';

  @override
  String get protocolWireGuardDesc => 'Classic WARP tunnel, lowest overhead';

  @override
  String get protocolGool => 'Gool';

  @override
  String get protocolGoolDesc => 'WARP inside WARP, slower but harder to block';

  @override
  String get transport => 'Connection type';

  @override
  String get transportH3 => 'HTTP/3 over QUIC';

  @override
  String get transportH3Desc =>
      'Faster, but your network has to leave UDP open';

  @override
  String get transportH2 => 'HTTP/2 over TCP';

  @override
  String get transportH2Desc =>
      'Looks like an ordinary website. Pick this when UDP is blocked';

  @override
  String get scanMode => 'Scan mode';

  @override
  String get scanTurbo => 'Turbo';

  @override
  String get scanTurboDesc => 'Fast, takes the first working gateway';

  @override
  String get scanBalanced => 'Balanced';

  @override
  String get scanBalancedDesc => 'Reasonable speed and reliability';

  @override
  String get scanThorough => 'Thorough';

  @override
  String get scanThoroughDesc => 'Deeper search, picks the lowest latency';

  @override
  String get scanStealth => 'Stealth';

  @override
  String get scanStealthDesc => 'Quiet and patient, less traffic noise';

  @override
  String get scanIronclad => 'Ironclad';

  @override
  String get scanIroncladDesc =>
      'Opens a real tunnel and runs a real HTTP check per candidate';

  @override
  String get obfuscation => 'Obfuscation';

  @override
  String get obfuscationOff => 'Off';

  @override
  String get obfuscationLight => 'Light';

  @override
  String get obfuscationBalanced => 'Balanced';

  @override
  String get obfuscationAggressive => 'Aggressive';

  @override
  String get endpoint => 'Server';

  @override
  String get endpointDesc =>
      'Type a server if you want a specific one, or leave it empty and it will find one';

  @override
  String get endpointAuto => 'Automatic';

  @override
  String get ipVersion => 'IP version';

  @override
  String get ipV4 => 'IPv4';

  @override
  String get ipV6 => 'IPv6';

  @override
  String get ipDual => 'Both';

  @override
  String get socksPort => 'SOCKS5 port';

  @override
  String get socksPortDesc => 'Local port the core listens on';

  @override
  String get allowLan => 'Allow LAN access';

  @override
  String get allowLanDesc => 'Let other devices on your network use this proxy';

  @override
  String get proxyOnly => 'Proxy only mode';

  @override
  String get proxyOnlyDesc => 'Expose SOCKS5 without capturing device traffic';

  @override
  String get splitTunnel => 'Split tunneling';

  @override
  String get splitTunnelDesc => 'Choose which apps bypass the tunnel';

  @override
  String get splitTunnelDisabled => 'Disabled';

  @override
  String get splitTunnelDisabledDesc =>
      'All app traffic goes through the tunnel';

  @override
  String get splitTunnelBlacklist => 'Bypass selected';

  @override
  String get splitTunnelBlacklistDesc => 'Selected apps skip the tunnel';

  @override
  String get showSystemApps => 'Show system apps';

  @override
  String get searchApps => 'Search apps';

  @override
  String get fragment => 'Send in pieces';

  @override
  String get fragmentDesc =>
      'Breaks the start of the connection into pieces so filtering cannot recognise it';

  @override
  String get logLevel => 'Log level';

  @override
  String get logLevelError => 'Error';

  @override
  String get logLevelWarn => 'Warning';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get logLevelDebug => 'Debug';

  @override
  String get logLevelTrace => 'Trace';

  @override
  String get perfProfile => 'Performance profile';

  @override
  String get perfProfileDesc => 'How much CPU and memory the core may use';

  @override
  String get perfAuto => 'Automatic';

  @override
  String get perfLow => 'Low';

  @override
  String get perfMedium => 'Medium';

  @override
  String get perfHigh => 'High';

  @override
  String get quickReconnect => 'Quick reconnect';

  @override
  String get quickReconnectDesc =>
      'Retry the last working gateway before a full rescan';

  @override
  String get resetSettings => 'Reset settings';

  @override
  String get resetSettingsDesc => 'Return everything to defaults';

  @override
  String get resetConfirmTitle => 'Reset settings?';

  @override
  String get resetConfirmBody =>
      'All preferences go back to their default values. Your saved identity is kept.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get copyLogs => 'Copy logs';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get logsEmpty =>
      'No logs yet. Connect once and they will show up here.';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get aboutBody =>
      'Oblivion is a free and open source app for reaching the internet without censorship. It costs nothing, and selling it or using it commercially is not allowed.';

  @override
  String get aboutCore => 'Core engine';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutSource => 'Source code';

  @override
  String get aboutLicense => 'License';

  @override
  String get vpnPermissionNeeded =>
      'VPN permission is required to route your traffic';

  @override
  String get vpnPermissionDenied =>
      'Permission denied, the tunnel cannot start';

  @override
  String get connectionFailedRetry =>
      'Could not establish a tunnel. Try another protocol or scan mode.';

  @override
  String get exitConfirm => 'Press back again to exit';

  @override
  String get notificationTitle => 'Oblivion';

  @override
  String get mapAttribution => 'Map data by OpenStreetMap contributors';

  @override
  String get sectionTls => 'TLS and camouflage';

  @override
  String get sectionReliability => 'Reliability';

  @override
  String get wgEndpoint => 'WireGuard server';

  @override
  String get wgEndpointDesc => 'Leave empty and it will pick one';

  @override
  String get h2Endpoint => 'HTTP/2 server';

  @override
  String get h2EndpointDesc => 'The server used in HTTP/2 mode';

  @override
  String get ech => 'Hide the site name';

  @override
  String get echDesc =>
      'Keeps the name of the site you open hidden from the network';

  @override
  String get fragmentSize => 'Fragment size';

  @override
  String get fragmentDelay => 'Fragment delay';

  @override
  String get rangeHint => 'A single number or a range such as 16-32';

  @override
  String get tlsGroups => 'TLS key groups';

  @override
  String get tlsGroupsDesc => 'Key share groups offered during the handshake';

  @override
  String get dataCheck => 'Check data really flows';

  @override
  String get dataCheckDesc =>
      'Do not say connected until real data has gone through';

  @override
  String get validateSeconds => 'Check timeout';

  @override
  String get validateSecondsDesc =>
      'How many seconds to wait before deciding the tunnel works';

  @override
  String get reconnectSeconds => 'Reconnect delay';

  @override
  String get reconnectSecondsDesc =>
      'How long to wait after a drop before trying again';

  @override
  String get wgKeepalive => 'Keep-alive interval';

  @override
  String get wgKeepaliveDesc =>
      'Send a small packet every few seconds so the connection stays open';

  @override
  String get wgProfileRetry => 'Retry other profiles';

  @override
  String get wgProfileRetryDesc =>
      'Try other obfuscation profiles while scanning';

  @override
  String get tabHome => 'Shield';

  @override
  String get slideToConnect => 'Slide to connect';

  @override
  String get releaseToConnect => 'Release to connect';

  @override
  String get aboutApp => 'App repository';

  @override
  String get aboutCoreRepo => 'Core repository';

  @override
  String get aboutCredits => 'Built on';

  @override
  String get aboutFooter =>
      'Oblivion is the app by bepass-org. The tunnel engine is Aether by Cluvex Studio.';

  @override
  String get connectAction => 'Connect';

  @override
  String get disconnectAction => 'Disconnect';

  @override
  String get retryAction => 'Try again';

  @override
  String get tunnelModeSection => 'Tunnel device';

  @override
  String get tunnelInterface => 'Interface name';

  @override
  String get tunnelInterfaceDesc => 'Name of the virtual network card';

  @override
  String get tunnelMtu => 'MTU';

  @override
  String get tunnelMtuDesc =>
      'Packet size. Lower it if the connection feels slow';

  @override
  String get tunnelDeviceState => 'Device state';

  @override
  String get tunnelDeviceEmbedded => 'Embedded';

  @override
  String get tunnelDeviceMissing => 'Not embedded';

  @override
  String get tunnelNeedsPrivileges => 'Needs elevated privileges';

  @override
  String get tunnelReady => 'Ready';

  @override
  String get tunnelModeActive => 'Full device tunnel';

  @override
  String get tunnelModeProxy => 'Proxy only';

  @override
  String get logsAll => 'All';

  @override
  String get logsSourceAether => 'Aether';

  @override
  String get logsSourceHev => 'Tunnel';

  @override
  String get logsFilterEmpty => 'Nothing found';

  @override
  String get logsCopied => 'Copied to clipboard';

  @override
  String get introSlogan => 'Internet for All, or No One';

  @override
  String get trayShow => 'Show Oblivion';

  @override
  String get trayHide => 'Hide to tray';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayStageIdle => 'Disconnected';

  @override
  String get trayStageBusy => 'Connecting';

  @override
  String get trayStageActive => 'Connected';

  @override
  String get fragmentNeedsHttp2 =>
      'Switches the transport to HTTP/2, the only one that carries a TLS ClientHello';

  @override
  String get transportUdp => 'UDP';

  @override
  String get transportWiw => 'WARP in WARP';

  @override
  String get dnsOverride => 'Tunnel the resolver';

  @override
  String get dnsOverrideDesc =>
      'Sends DNS through the tunnel instead of your ISP resolver';

  @override
  String get dnsServers => 'Resolver addresses';

  @override
  String get dnsServersDesc => 'Used while the tunnel is up';

  @override
  String get switchOff => 'Off';

  @override
  String get switchOn => 'Secure';

  @override
  String get chipFullTunnel => 'Full tunnel';

  @override
  String get chipProxyOnly => 'Proxy only';

  @override
  String get chipNotProtected => 'Not protected';

  @override
  String get trafficUnprotected => 'your traffic is not protected';

  @override
  String sinceLabel(String time) {
    return 'since $time';
  }

  @override
  String get exitNode => 'Exit node';

  @override
  String get gatewayLabel => 'Gateway';

  @override
  String get gatewayAutoHint => 'Aether picks the fastest clean edge';

  @override
  String get metricDownload => 'Download';

  @override
  String get metricUpload => 'Upload';

  @override
  String get metricSocks => 'SOCKS5';

  @override
  String get unitPort => 'port';

  @override
  String get mapYou => 'You';

  @override
  String get mapExit => 'Exit';

  @override
  String settingsSubtitle(String version) {
    return 'Aether core · $version';
  }

  @override
  String get fullTunnelDesc => 'Route every app, not just the SOCKS5 port';

  @override
  String get sectionDeviceTunnel => 'Device tunnel';

  @override
  String get sectionDevice => 'Device';

  @override
  String get logsLive => 'live from the core';

  @override
  String get aboutInMemory => 'In memory of';

  @override
  String get aboutHev => 'hev-socks5-tunnel';

  @override
  String get aboutHevDesc => 'the tun device that carries your packets';

  @override
  String aboutAppSummary(String app, String core) {
    return 'app $app · core aether $core';
  }

  @override
  String get introHeadline => 'Private by default';

  @override
  String get introBody =>
      'Oblivion routes your traffic through the Aether core, so the network you are on cannot read or shape it.';

  @override
  String get introFeatureTunnelTitle => 'MASQUE over QUIC';

  @override
  String get introFeatureTunnelBody =>
      'A tunnel that looks like ordinary HTTPS traffic.';

  @override
  String get introFeatureAccountTitle => 'Nothing to sign up for';

  @override
  String get introFeatureAccountBody =>
      'A dedicated identity is provisioned on first launch.';

  @override
  String get introFeatureControlTitle => 'Choose what goes through';

  @override
  String get introFeatureControlBody =>
      'Split tunnel, custom resolver, per protocol control.';

  @override
  String get introGetStarted => 'Get started';

  @override
  String get introFooter => 'Free and open source · GPL-3.0';

  @override
  String get splitHeaderSubtitle =>
      'Apps listed here bypass the tunnel entirely';

  @override
  String splitBypassCount(String count) {
    return '$count apps bypass the tunnel';
  }

  @override
  String get apply => 'Apply';

  @override
  String get geoUnavailable => 'location could not be detected';

  @override
  String get routingMode => 'Routing mode';

  @override
  String get routingSocks => 'SOCKS5 only';

  @override
  String get routingSocksDesc =>
      'Only apps you point at the local port go through the tunnel';

  @override
  String get routingSystem => 'System proxy';

  @override
  String get routingSystemDesc =>
      'Sets the desktop proxy for every app, no admin rights needed';

  @override
  String get routingTunnelDesc =>
      'Routes every packet of the device, needs administrator rights';

  @override
  String get chipSystemProxy => 'System proxy';

  @override
  String get chipSocksOnly => 'SOCKS only';

  @override
  String get scannerOff => 'Scanner off, your gateway is used directly';

  @override
  String get endpointManualHint => 'Set a gateway to skip scanning entirely';

  @override
  String get notificationChannelName => 'Tunnel status';

  @override
  String get notificationChannelDesc =>
      'Shows whether the tunnel is up and lets you disconnect';

  @override
  String get notificationPermissionTitle => 'Allow notifications';

  @override
  String get notificationPermissionBody =>
      'Oblivion needs a notification to keep the tunnel alive in the background';
}
