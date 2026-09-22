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
  String get appTagline => 'Free internet for all, or no one';

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
  String get splitTunnelWhitelist => 'Only selected';

  @override
  String get splitTunnelWhitelistDesc =>
      'Only the apps you pick go through the tunnel, everything else goes out directly';

  @override
  String splitAllowCount(String count) {
    return '$count apps go through the tunnel';
  }

  @override
  String get splitAllowEmpty =>
      'Pick at least one app, or nothing will go through the tunnel';

  @override
  String get splitTunnelPick => 'Which apps';

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
  String get obfuscationOffDesc => 'No reshaping, the fastest handshake';

  @override
  String get obfuscationLightDesc =>
      'A light touch, for networks that barely look';

  @override
  String get obfuscationBalancedDesc =>
      'The usual choice, works on most networks';

  @override
  String get obfuscationAggressiveDesc =>
      'Heaviest reshaping, for networks that fingerprint hard';

  @override
  String get ipV4Desc => 'Reach gateways over IPv4 only';

  @override
  String get ipV6Desc => 'Reach gateways over IPv6 only';

  @override
  String get ipDualDesc => 'Try both, keep whichever answers';

  @override
  String get logLevelErrorDesc => 'Only what went wrong';

  @override
  String get logLevelWarnDesc => 'Errors and warnings';

  @override
  String get logLevelInfoDesc => 'The usual choice, one line per step';

  @override
  String get logLevelDebugDesc =>
      'Everything the core does, for chasing a problem';

  @override
  String get logLevelTraceDesc => 'Every packet decision, very noisy';

  @override
  String get perfAutoDesc => 'Match the device the app is running on';

  @override
  String get perfLowDesc => 'Smallest buffers, easiest on an old phone';

  @override
  String get perfMediumDesc => 'A middle ground for everyday hardware';

  @override
  String get perfHighDesc => 'Largest buffers, fastest on a strong device';

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
  String get aboutCore => 'Aether engine';

  @override
  String get aboutPsiphonCore => 'Psiphon engine';

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
  String get wiwSection => 'WARP-in-WARP hops';

  @override
  String get wiwSectionDesc =>
      'Hand the two hops over instead of waiting for a sweep.';

  @override
  String get wiwOuter => 'Outer hop';

  @override
  String get wiwOuterDesc =>
      'The edge your network sees. Leave blank to let the scan pick it.';

  @override
  String get wiwInner => 'Inner hop';

  @override
  String get wiwInnerDesc =>
      'The edge reached through the outer one. Leave blank to let the scan pick it.';

  @override
  String get wiwHint =>
      'Write an address and a port together, such as 162.159.192.1:2408. The port is required, and the two hops must be different addresses.';

  @override
  String get wiwScanned => 'Scanned';

  @override
  String get wiwManual => 'Manual';

  @override
  String get wiwInvalidEndpoint =>
      'That is not an address and port. Write them together, such as 162.159.192.1:2408.';

  @override
  String get wiwSameEdge =>
      'Both hops point at the same edge. WARP-in-WARP needs two different addresses.';

  @override
  String get endpointIgnoredOnGool =>
      'Not used by WARP-in-WARP; name the two hops instead.';

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
      'Largest packet the tunnel carries whole. Between 1280 and 9000';

  @override
  String tunnelMtuMeasured(String path) {
    return 'Measured path $path bytes';
  }

  @override
  String get mtuOptimize => 'Find the best MTU';

  @override
  String get mtuOptimizeDesc =>
      'Measures your real connection and keeps the largest packet that survives it';

  @override
  String get mtuOptimizeTitle => 'MTU optimizer';

  @override
  String get mtuOptimizeMeasuring => 'Measuring your connection';

  @override
  String get mtuOptimizeHint =>
      'A handful of tiny probes go out to public servers. This takes a few seconds.';

  @override
  String get mtuOptimizeLink => 'Local link';

  @override
  String get mtuOptimizePath => 'Internet path';

  @override
  String get mtuOptimizeOverhead => 'Tunnel overhead';

  @override
  String get mtuOptimizeTransport => 'Transport';

  @override
  String get mtuOptimizeResult => 'Best MTU';

  @override
  String get mtuOptimizeCore => 'Core packet size';

  @override
  String get mtuOptimizeApply => 'Apply';

  @override
  String get mtuOptimizeRetry => 'Measure again';

  @override
  String get mtuOptimizeUnchanged =>
      'Your MTU is already the best value for this network';

  @override
  String get mtuOptimizeNarrow =>
      'This network only carries small packets, so the tunnel is set to match it';

  @override
  String get mtuOptimizeTight =>
      'The path is too narrow even for the MASQUE handshake. Try HTTP/2 or WireGuard if the tunnel will not come up.';

  @override
  String get mtuOptimizeBusy =>
      'Disconnect first, so the measurement sees your real network instead of the tunnel';

  @override
  String get mtuOptimizeFailed => 'The measurement did not finish';

  @override
  String get mtuOptimizeFailedUnreachable =>
      'No probe came back. The network may be blocking UDP, or you are offline.';

  @override
  String get mtuOptimizeFailedDf =>
      'This device would not send unfragmented probes, so the path cannot be measured here.';

  @override
  String get mtuOptimizeFailedSocket =>
      'The app could not open a socket for the measurement';

  @override
  String get mtuOptimizePartial =>
      'The measurement ran out of time, so the value below is a safe lower bound';

  @override
  String mtuRangeRefusal(String min, String max) {
    return 'Enter a number between $min and $max';
  }

  @override
  String portRangeRefusal(String min, String max) {
    return 'Enter a port between $min and $max';
  }

  @override
  String secondsRangeRefusal(String min, String max) {
    return 'Enter a number of seconds between $min and $max';
  }

  @override
  String get dnsRefusal => 'Enter one or two IP addresses';

  @override
  String get settingsNeedReconnect => 'Reconnect for this to take effect';

  @override
  String get devNote => 'Read the developer note';

  @override
  String get devNoteDesc => 'How to pick a protocol on a restricted network';

  @override
  String get devNoteTitle => 'Note from the developer';

  @override
  String get devNoteIntro =>
      'On heavily filtered networks, and in Iran above all, MASQUE over HTTP/3 rarely stays up. HTTP/3 rides on QUIC, and QUIC is UDP, which is the first thing those networks throttle or drop. If your line is restricted, do not start there.';

  @override
  String get devNoteHttp2Title => 'Start with HTTP/2';

  @override
  String get devNoteHttp2Body =>
      'In Settings, set Connection type to HTTP/2 over TCP. It looks like ordinary web traffic, and on a restricted line it is by far the steadiest choice.';

  @override
  String get devNoteWireGuardTitle => 'Or use WireGuard';

  @override
  String get devNoteWireGuardBody =>
      'Set Protocol to WireGuard. Mind the scanner: on Balanced the search takes a while, so give it time before you decide it failed. If you want a result quickly, set Scan mode to Turbo.';

  @override
  String get devNoteGoolTitle => 'Gool usually works well';

  @override
  String get devNoteGoolBody =>
      'From Iran, Gool almost always comes out on a German address and gives no trouble. Once in a while it lands back on an Iranian address. Disconnect and connect again a couple of times and it clears up.';

  @override
  String get devNoteDismiss => 'Got it';

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
  String get introSlogan => 'Free Internet for All, or No One';

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

  @override
  String get coreEngine => 'Core';

  @override
  String get coreEngineDesc => 'Which tunnel engine to run';

  @override
  String get coreAether => 'Aether';

  @override
  String get coreAetherDesc => 'Cloudflare WARP and MASQUE';

  @override
  String get corePsiphon => 'Psiphon';

  @override
  String get corePsiphonDesc => 'Psiphon network with CDN fronting';

  @override
  String get coreChain => 'Aether + Psiphon';

  @override
  String get coreChainDesc =>
      'Bring up Aether first, then run Psiphon through it.';

  @override
  String get chainOrder => 'Chain order';

  @override
  String chainOrderDesc(String transport) {
    return '$transport connects first, then Psiphon dials out through it.';
  }

  @override
  String get chainNeedsTcp =>
      'Chained through Aether, so Psiphon keeps to its TCP protocols.';

  @override
  String get psiphonSettings => 'Psiphon';

  @override
  String get psiphonCountry => 'Country';

  @override
  String get psiphonCountryAuto => 'Automatic';

  @override
  String get psiphonCountryDesc => 'Where traffic leaves the Psiphon network';

  @override
  String get psiphonMode => 'Mode';

  @override
  String get psiphonModeCdn => 'CDN fronting';

  @override
  String get psiphonModeCdnDesc => 'Reach servers through CDN edges';

  @override
  String get psiphonModeConduit => 'Conduit';

  @override
  String get psiphonModeConduitDesc => 'Route through volunteer in-proxy peers';

  @override
  String get psiphonModeAuto => 'Automatic';

  @override
  String get psiphonModeAutoDesc =>
      'Let Psiphon pick any protocol it can reach';

  @override
  String get psiphonModeDirect => 'Direct';

  @override
  String get psiphonModeDirectDesc => 'Connect straight to Psiphon servers';

  @override
  String get psiphonCdnFronting => 'CDN fronting';

  @override
  String get psiphonCdnIps => 'Edge addresses';

  @override
  String get psiphonCdnIpsDesc =>
      'Extra IPv4 addresses or CIDR ranges to scan, one per line';

  @override
  String get psiphonCdnSni => 'SNI names';

  @override
  String get psiphonCdnSniDesc =>
      'Domain names to present in TLS, one per line';

  @override
  String get psiphonConduitPeers => 'Peers';

  @override
  String get psiphonConduitPeersAuto => 'Automatic';

  @override
  String get psiphonConduitPeersAutoDesc =>
      'Prefer private peers, fall back to public ones';

  @override
  String get psiphonConduitPeersPrivate => 'Private only';

  @override
  String get psiphonConduitPeersPrivateDesc =>
      'Only peers paired with this build';

  @override
  String get psiphonConduitPeersPublic => 'Public only';

  @override
  String get psiphonConduitPeersPublicDesc =>
      'Only volunteer peers open to everyone';

  @override
  String get psiphonRejectCensoredPeers => 'Skip censored regions';

  @override
  String get psiphonRejectCensoredPeersDesc =>
      'Refuse peers hosted in heavily censored countries';

  @override
  String get psiphonUnprovisioned =>
      'This build carries no Psiphon credentials, so the Psiphon core cannot connect';

  @override
  String get psiphonConduitUnavailable =>
      'This build embeds no conduit credentials, so conduit mode cannot connect';

  @override
  String get psiphonCountryIgnoredOnConduit =>
      'Conduit reaches the network through volunteer peers, so the country is chosen for you';

  @override
  String get psiphonNotAvailable =>
      'Psiphon settings apply only when the Psiphon core is selected';

  @override
  String get aetherOnlySection => 'These settings apply to the Aether core';

  @override
  String get fastFirstConnect => 'Fast first connect';

  @override
  String get fastFirstConnectDesc =>
      'Try a plain connection first, then fall back to obfuscation';

  @override
  String get protocolMim => 'MASQUE-in-MASQUE';

  @override
  String get protocolMimDesc =>
      'Two MASQUE hops, for an exit address in a different range';

  @override
  String get scanVerified => 'Verified';

  @override
  String get scanVerifiedDesc =>
      'Only edges measured to answer, never a guessed neighbour';

  @override
  String get obfuscationFirewall => 'Firewall';

  @override
  String get obfuscationFirewallDesc =>
      'The MASQUE default, tuned for a filtering firewall';

  @override
  String get obfuscationGfw => 'GFW';

  @override
  String get obfuscationGfwDesc =>
      'The loudest profile, for when nothing else gets through';

  @override
  String get torSection => 'Tor';

  @override
  String get torModeTitle => 'Tor';

  @override
  String get torOff => 'Off';

  @override
  String get torOffDesc => 'No Tor';

  @override
  String get torChain => 'Tor inside the tunnel';

  @override
  String get torChainDesc =>
      'You, WARP, Tor, the internet. The exit is a Tor exit';

  @override
  String get torReverse => 'Tunnel through Tor';

  @override
  String get torReverseDesc =>
      'WARP is reached from a Tor exit, so your network never sees WARP';

  @override
  String get torOnly => 'Tor only';

  @override
  String get torOnlyDesc => 'No tunnel underneath, plain Tor';

  @override
  String get torRelaysTitle => 'Bridge source';

  @override
  String get torRelaysDesc =>
      'Where bridges come from when the network blocks Tor';

  @override
  String get torRelaysAuto => 'BridgeDB and relays';

  @override
  String get torRelaysOnly => 'Relays only';

  @override
  String get torRelaysOff => 'BridgeDB only';

  @override
  String get exitLocTitle => 'Exit country';

  @override
  String get exitLocDesc =>
      'Refuse a tunnel that comes out in a country you do not want, and reconnect. Leave empty to accept any';

  @override
  String get exitLocHint => '!IR,AZ,RU';

  @override
  String get activeModeLabel => 'Mode';
}
