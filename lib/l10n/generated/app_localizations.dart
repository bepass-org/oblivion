import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Oblivion'**
  String get appName;

  /// No description provided for @appDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Oblivion'**
  String get appDisplayName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Internet for all, or no one'**
  String get appTagline;

  /// No description provided for @introMeaning.
  ///
  /// In en, this message translates to:
  /// **'Means \"unawareness, ignorance\"'**
  String get introMeaning;

  /// No description provided for @introCredit.
  ///
  /// In en, this message translates to:
  /// **'Built through the efforts of #Yousef_Ghobadi and dozens of known and anonymous activists, so that free access to the internet belongs to everyone.'**
  String get introCredit;

  /// No description provided for @memorialTitle.
  ///
  /// In en, this message translates to:
  /// **'In memory of those killed on 18 and 19 Dey'**
  String get memorialTitle;

  /// No description provided for @memorialBody.
  ///
  /// In en, this message translates to:
  /// **'Unarmed people, shot dead by the forces of the Islamic Republic'**
  String get memorialBody;

  /// No description provided for @memorialVow.
  ///
  /// In en, this message translates to:
  /// **'We will not forgive, we will not forget'**
  String get memorialVow;

  /// No description provided for @introSegaro.
  ///
  /// In en, this message translates to:
  /// **'#Segaro'**
  String get introSegaro;

  /// No description provided for @introYousef.
  ///
  /// In en, this message translates to:
  /// **'#Yousef_Ghobadi'**
  String get introYousef;

  /// No description provided for @introContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get introContinue;

  /// No description provided for @stateDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get stateDisconnected;

  /// No description provided for @stateConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get stateConnecting;

  /// No description provided for @stateValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating tunnel'**
  String get stateValidating;

  /// No description provided for @stateConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get stateConnected;

  /// No description provided for @stateDisconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get stateDisconnecting;

  /// No description provided for @stateFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get stateFailed;

  /// No description provided for @tapToConnect.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get tapToConnect;

  /// No description provided for @tapToDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Tap to disconnect'**
  String get tapToDisconnect;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @exitLocation.
  ///
  /// In en, this message translates to:
  /// **'Exit location'**
  String get exitLocation;

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting location'**
  String get detectingLocation;

  /// No description provided for @locationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get locationUnknown;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @sectionCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get sectionCore;

  /// No description provided for @sectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get sectionNetwork;

  /// No description provided for @sectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get sectionAdvanced;

  /// No description provided for @routingTunnelDescMobile.
  ///
  /// In en, this message translates to:
  /// **'Routes all device traffic through the tunnel'**
  String get routingTunnelDescMobile;

  /// No description provided for @tunnelDegraded.
  ///
  /// In en, this message translates to:
  /// **'Only the local proxy is up, device traffic is not going through the tunnel'**
  String get tunnelDegraded;

  /// No description provided for @tunnelDegradedHint.
  ///
  /// In en, this message translates to:
  /// **'Full tunnel mode needs the app to run with administrator rights'**
  String get tunnelDegradedHint;

  /// No description provided for @zeroTrust.
  ///
  /// In en, this message translates to:
  /// **'Organization account'**
  String get zeroTrust;

  /// No description provided for @zeroTrustDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with a Cloudflare Zero Trust account instead of a personal one'**
  String get zeroTrustDesc;

  /// No description provided for @zeroTrustOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get zeroTrustOff;

  /// No description provided for @zeroTrustTeam.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get zeroTrustTeam;

  /// No description provided for @zeroTrustTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'The name in your <team>.cloudflareaccess.com address'**
  String get zeroTrustTeamDesc;

  /// No description provided for @zeroTrustToken.
  ///
  /// In en, this message translates to:
  /// **'Login token'**
  String get zeroTrustToken;

  /// No description provided for @zeroTrustTokenDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in at <team>.cloudflareaccess.com/warp in a browser and paste the token here'**
  String get zeroTrustTokenDesc;

  /// No description provided for @zeroTrustServiceToken.
  ///
  /// In en, this message translates to:
  /// **'Service token'**
  String get zeroTrustServiceToken;

  /// No description provided for @zeroTrustClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get zeroTrustClientId;

  /// No description provided for @zeroTrustClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get zeroTrustClientSecret;

  /// No description provided for @zeroTrustGateway.
  ///
  /// In en, this message translates to:
  /// **'Send traffic through the organization gateway'**
  String get zeroTrustGateway;

  /// No description provided for @zeroTrustGatewayDesc.
  ///
  /// In en, this message translates to:
  /// **'The organization\'s filtering and logging apply. It adds a hop inside the tunnel and your browsing is recorded.'**
  String get zeroTrustGatewayDesc;

  /// No description provided for @zeroTrustReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to connect'**
  String get zeroTrustReady;

  /// No description provided for @zeroTrustNeedsToken.
  ///
  /// In en, this message translates to:
  /// **'Add an email address, a login token or a service token'**
  String get zeroTrustNeedsToken;

  /// No description provided for @zeroTrustSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get zeroTrustSet;

  /// No description provided for @zeroTrustClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the organization account'**
  String get zeroTrustClear;

  /// No description provided for @zeroTrustEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get zeroTrustEmail;

  /// No description provided for @zeroTrustEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'The simplest way in. Cloudflare emails a one-time code when you connect, and the app asks you for it.'**
  String get zeroTrustEmailDesc;

  /// No description provided for @zeroTrustSignIn.
  ///
  /// In en, this message translates to:
  /// **'How you sign in'**
  String get zeroTrustSignIn;

  /// No description provided for @zeroTrustCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Login code'**
  String get zeroTrustCodeTitle;

  /// No description provided for @zeroTrustCodeBody.
  ///
  /// In en, this message translates to:
  /// **'A code was emailed to {email}. Enter it to finish signing in.'**
  String zeroTrustCodeBody(String email);

  /// No description provided for @zeroTrustCodeRetry.
  ///
  /// In en, this message translates to:
  /// **'That code was not accepted. Check your mailbox and try again.'**
  String get zeroTrustCodeRetry;

  /// No description provided for @zeroTrustCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Code from the email'**
  String get zeroTrustCodePlaceholder;

  /// No description provided for @zeroTrustCodeSend.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get zeroTrustCodeSend;

  /// No description provided for @zeroTrustCodeLost.
  ///
  /// In en, this message translates to:
  /// **'The core is no longer waiting for a code'**
  String get zeroTrustCodeLost;

  /// No description provided for @notificationConnected.
  ///
  /// In en, this message translates to:
  /// **'Tunnel active'**
  String get notificationConnected;

  /// No description provided for @notificationConnecting.
  ///
  /// In en, this message translates to:
  /// **'Establishing tunnel'**
  String get notificationConnecting;

  /// No description provided for @notificationDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get notificationDisconnect;

  /// No description provided for @sectionRules.
  ///
  /// In en, this message translates to:
  /// **'Where traffic goes'**
  String get sectionRules;

  /// No description provided for @advancedDesc.
  ///
  /// In en, this message translates to:
  /// **'DNS, port, traffic rules and finer settings'**
  String get advancedDesc;

  /// No description provided for @ruleBlock.
  ///
  /// In en, this message translates to:
  /// **'Blocked sites'**
  String get ruleBlock;

  /// No description provided for @ruleBlockDesc.
  ///
  /// In en, this message translates to:
  /// **'These addresses are not allowed to open'**
  String get ruleBlockDesc;

  /// No description provided for @ruleDirect.
  ///
  /// In en, this message translates to:
  /// **'Skip the tunnel'**
  String get ruleDirect;

  /// No description provided for @ruleDirectDesc.
  ///
  /// In en, this message translates to:
  /// **'These open through your own connection instead of the tunnel'**
  String get ruleDirectDesc;

  /// No description provided for @ruleNone.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get ruleNone;

  /// No description provided for @ruleHint.
  ///
  /// In en, this message translates to:
  /// **'One address per line. A site name, an IP address or a port number all work.'**
  String get ruleHint;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @protocolMasque.
  ///
  /// In en, this message translates to:
  /// **'MASQUE'**
  String get protocolMasque;

  /// No description provided for @protocolMasqueDesc.
  ///
  /// In en, this message translates to:
  /// **'Modern QUIC/HTTP-3 transport, best on healthy networks'**
  String get protocolMasqueDesc;

  /// No description provided for @protocolWireGuard.
  ///
  /// In en, this message translates to:
  /// **'WireGuard'**
  String get protocolWireGuard;

  /// No description provided for @protocolWireGuardDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic WARP tunnel, lowest overhead'**
  String get protocolWireGuardDesc;

  /// No description provided for @protocolGool.
  ///
  /// In en, this message translates to:
  /// **'Gool'**
  String get protocolGool;

  /// No description provided for @protocolGoolDesc.
  ///
  /// In en, this message translates to:
  /// **'WARP inside WARP, slower but harder to block'**
  String get protocolGoolDesc;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Connection type'**
  String get transport;

  /// No description provided for @transportH3.
  ///
  /// In en, this message translates to:
  /// **'HTTP/3 over QUIC'**
  String get transportH3;

  /// No description provided for @transportH3Desc.
  ///
  /// In en, this message translates to:
  /// **'Faster, but your network has to leave UDP open'**
  String get transportH3Desc;

  /// No description provided for @transportH2.
  ///
  /// In en, this message translates to:
  /// **'HTTP/2 over TCP'**
  String get transportH2;

  /// No description provided for @transportH2Desc.
  ///
  /// In en, this message translates to:
  /// **'Looks like an ordinary website. Pick this when UDP is blocked'**
  String get transportH2Desc;

  /// No description provided for @scanMode.
  ///
  /// In en, this message translates to:
  /// **'Scan mode'**
  String get scanMode;

  /// No description provided for @scanTurbo.
  ///
  /// In en, this message translates to:
  /// **'Turbo'**
  String get scanTurbo;

  /// No description provided for @scanTurboDesc.
  ///
  /// In en, this message translates to:
  /// **'Fast, takes the first working gateway'**
  String get scanTurboDesc;

  /// No description provided for @scanBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get scanBalanced;

  /// No description provided for @scanBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reasonable speed and reliability'**
  String get scanBalancedDesc;

  /// No description provided for @scanThorough.
  ///
  /// In en, this message translates to:
  /// **'Thorough'**
  String get scanThorough;

  /// No description provided for @scanThoroughDesc.
  ///
  /// In en, this message translates to:
  /// **'Deeper search, picks the lowest latency'**
  String get scanThoroughDesc;

  /// No description provided for @scanStealth.
  ///
  /// In en, this message translates to:
  /// **'Stealth'**
  String get scanStealth;

  /// No description provided for @scanStealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Quiet and patient, less traffic noise'**
  String get scanStealthDesc;

  /// No description provided for @scanIronclad.
  ///
  /// In en, this message translates to:
  /// **'Ironclad'**
  String get scanIronclad;

  /// No description provided for @scanIroncladDesc.
  ///
  /// In en, this message translates to:
  /// **'Opens a real tunnel and runs a real HTTP check per candidate'**
  String get scanIroncladDesc;

  /// No description provided for @obfuscation.
  ///
  /// In en, this message translates to:
  /// **'Obfuscation'**
  String get obfuscation;

  /// No description provided for @obfuscationOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get obfuscationOff;

  /// No description provided for @obfuscationLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get obfuscationLight;

  /// No description provided for @obfuscationBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get obfuscationBalanced;

  /// No description provided for @obfuscationAggressive.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get obfuscationAggressive;

  /// No description provided for @endpoint.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get endpoint;

  /// No description provided for @endpointDesc.
  ///
  /// In en, this message translates to:
  /// **'Type a server if you want a specific one, or leave it empty and it will find one'**
  String get endpointDesc;

  /// No description provided for @endpointAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get endpointAuto;

  /// No description provided for @ipVersion.
  ///
  /// In en, this message translates to:
  /// **'IP version'**
  String get ipVersion;

  /// No description provided for @ipV4.
  ///
  /// In en, this message translates to:
  /// **'IPv4'**
  String get ipV4;

  /// No description provided for @ipV6.
  ///
  /// In en, this message translates to:
  /// **'IPv6'**
  String get ipV6;

  /// No description provided for @ipDual.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get ipDual;

  /// No description provided for @socksPort.
  ///
  /// In en, this message translates to:
  /// **'SOCKS5 port'**
  String get socksPort;

  /// No description provided for @socksPortDesc.
  ///
  /// In en, this message translates to:
  /// **'Local port the core listens on'**
  String get socksPortDesc;

  /// No description provided for @allowLan.
  ///
  /// In en, this message translates to:
  /// **'Allow LAN access'**
  String get allowLan;

  /// No description provided for @allowLanDesc.
  ///
  /// In en, this message translates to:
  /// **'Let other devices on your network use this proxy'**
  String get allowLanDesc;

  /// No description provided for @proxyOnly.
  ///
  /// In en, this message translates to:
  /// **'Proxy only mode'**
  String get proxyOnly;

  /// No description provided for @proxyOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Expose SOCKS5 without capturing device traffic'**
  String get proxyOnlyDesc;

  /// No description provided for @splitTunnel.
  ///
  /// In en, this message translates to:
  /// **'Split tunneling'**
  String get splitTunnel;

  /// No description provided for @splitTunnelDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which apps bypass the tunnel'**
  String get splitTunnelDesc;

  /// No description provided for @splitTunnelDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get splitTunnelDisabled;

  /// No description provided for @splitTunnelDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'All app traffic goes through the tunnel'**
  String get splitTunnelDisabledDesc;

  /// No description provided for @splitTunnelBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Bypass selected'**
  String get splitTunnelBlacklist;

  /// No description provided for @splitTunnelBlacklistDesc.
  ///
  /// In en, this message translates to:
  /// **'Selected apps skip the tunnel'**
  String get splitTunnelBlacklistDesc;

  /// No description provided for @showSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Show system apps'**
  String get showSystemApps;

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// No description provided for @fragment.
  ///
  /// In en, this message translates to:
  /// **'Send in pieces'**
  String get fragment;

  /// No description provided for @fragmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Breaks the start of the connection into pieces so filtering cannot recognise it'**
  String get fragmentDesc;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get logLevel;

  /// No description provided for @logLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logLevelError;

  /// No description provided for @logLevelWarn.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logLevelWarn;

  /// No description provided for @logLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logLevelInfo;

  /// No description provided for @logLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logLevelDebug;

  /// No description provided for @logLevelTrace.
  ///
  /// In en, this message translates to:
  /// **'Trace'**
  String get logLevelTrace;

  /// No description provided for @perfProfile.
  ///
  /// In en, this message translates to:
  /// **'Performance profile'**
  String get perfProfile;

  /// No description provided for @perfProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'How much CPU and memory the core may use'**
  String get perfProfileDesc;

  /// No description provided for @perfAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get perfAuto;

  /// No description provided for @perfLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get perfLow;

  /// No description provided for @perfMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get perfMedium;

  /// No description provided for @perfHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get perfHigh;

  /// No description provided for @quickReconnect.
  ///
  /// In en, this message translates to:
  /// **'Quick reconnect'**
  String get quickReconnect;

  /// No description provided for @quickReconnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Retry the last working gateway before a full rescan'**
  String get quickReconnectDesc;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset settings'**
  String get resetSettings;

  /// No description provided for @resetSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Return everything to defaults'**
  String get resetSettingsDesc;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All preferences go back to their default values. Your saved identity is kept.'**
  String get resetConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @copyLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy logs'**
  String get copyLogs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet. Connect once and they will show up here.'**
  String get logsEmpty;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Oblivion is a free and open source app for reaching the internet without censorship. It costs nothing, and selling it or using it commercially is not allowed.'**
  String get aboutBody;

  /// No description provided for @aboutCore.
  ///
  /// In en, this message translates to:
  /// **'Aether engine'**
  String get aboutCore;

  /// No description provided for @aboutPsiphonCore.
  ///
  /// In en, this message translates to:
  /// **'Psiphon engine'**
  String get aboutPsiphonCore;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutSource.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSource;

  /// No description provided for @aboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicense;

  /// No description provided for @vpnPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'VPN permission is required to route your traffic'**
  String get vpnPermissionNeeded;

  /// No description provided for @vpnPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied, the tunnel cannot start'**
  String get vpnPermissionDenied;

  /// No description provided for @connectionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not establish a tunnel. Try another protocol or scan mode.'**
  String get connectionFailedRetry;

  /// No description provided for @exitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get exitConfirm;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Oblivion'**
  String get notificationTitle;

  /// No description provided for @mapAttribution.
  ///
  /// In en, this message translates to:
  /// **'Map data by OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @sectionTls.
  ///
  /// In en, this message translates to:
  /// **'TLS and camouflage'**
  String get sectionTls;

  /// No description provided for @sectionReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get sectionReliability;

  /// No description provided for @wgEndpoint.
  ///
  /// In en, this message translates to:
  /// **'WireGuard server'**
  String get wgEndpoint;

  /// No description provided for @wgEndpointDesc.
  ///
  /// In en, this message translates to:
  /// **'Leave empty and it will pick one'**
  String get wgEndpointDesc;

  /// No description provided for @h2Endpoint.
  ///
  /// In en, this message translates to:
  /// **'HTTP/2 server'**
  String get h2Endpoint;

  /// No description provided for @h2EndpointDesc.
  ///
  /// In en, this message translates to:
  /// **'The server used in HTTP/2 mode'**
  String get h2EndpointDesc;

  /// No description provided for @wiwSection.
  ///
  /// In en, this message translates to:
  /// **'WARP-in-WARP hops'**
  String get wiwSection;

  /// No description provided for @wiwSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Hand the two hops over instead of waiting for a sweep.'**
  String get wiwSectionDesc;

  /// No description provided for @wiwOuter.
  ///
  /// In en, this message translates to:
  /// **'Outer hop'**
  String get wiwOuter;

  /// No description provided for @wiwOuterDesc.
  ///
  /// In en, this message translates to:
  /// **'The edge your network sees. Leave blank to let the scan pick it.'**
  String get wiwOuterDesc;

  /// No description provided for @wiwInner.
  ///
  /// In en, this message translates to:
  /// **'Inner hop'**
  String get wiwInner;

  /// No description provided for @wiwInnerDesc.
  ///
  /// In en, this message translates to:
  /// **'The edge reached through the outer one. Leave blank to let the scan pick it.'**
  String get wiwInnerDesc;

  /// No description provided for @wiwHint.
  ///
  /// In en, this message translates to:
  /// **'Write an address and a port together, such as 162.159.192.1:2408. The port is required, and the two hops must be different addresses.'**
  String get wiwHint;

  /// No description provided for @wiwScanned.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get wiwScanned;

  /// No description provided for @wiwManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get wiwManual;

  /// No description provided for @wiwInvalidEndpoint.
  ///
  /// In en, this message translates to:
  /// **'That is not an address and port. Write them together, such as 162.159.192.1:2408.'**
  String get wiwInvalidEndpoint;

  /// No description provided for @wiwSameEdge.
  ///
  /// In en, this message translates to:
  /// **'Both hops point at the same edge. WARP-in-WARP needs two different addresses.'**
  String get wiwSameEdge;

  /// No description provided for @endpointIgnoredOnGool.
  ///
  /// In en, this message translates to:
  /// **'Not used by WARP-in-WARP; name the two hops instead.'**
  String get endpointIgnoredOnGool;

  /// No description provided for @ech.
  ///
  /// In en, this message translates to:
  /// **'Hide the site name'**
  String get ech;

  /// No description provided for @echDesc.
  ///
  /// In en, this message translates to:
  /// **'Keeps the name of the site you open hidden from the network'**
  String get echDesc;

  /// No description provided for @fragmentSize.
  ///
  /// In en, this message translates to:
  /// **'Fragment size'**
  String get fragmentSize;

  /// No description provided for @fragmentDelay.
  ///
  /// In en, this message translates to:
  /// **'Fragment delay'**
  String get fragmentDelay;

  /// No description provided for @rangeHint.
  ///
  /// In en, this message translates to:
  /// **'A single number or a range such as 16-32'**
  String get rangeHint;

  /// No description provided for @tlsGroups.
  ///
  /// In en, this message translates to:
  /// **'TLS key groups'**
  String get tlsGroups;

  /// No description provided for @tlsGroupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Key share groups offered during the handshake'**
  String get tlsGroupsDesc;

  /// No description provided for @dataCheck.
  ///
  /// In en, this message translates to:
  /// **'Check data really flows'**
  String get dataCheck;

  /// No description provided for @dataCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Do not say connected until real data has gone through'**
  String get dataCheckDesc;

  /// No description provided for @validateSeconds.
  ///
  /// In en, this message translates to:
  /// **'Check timeout'**
  String get validateSeconds;

  /// No description provided for @validateSecondsDesc.
  ///
  /// In en, this message translates to:
  /// **'How many seconds to wait before deciding the tunnel works'**
  String get validateSecondsDesc;

  /// No description provided for @reconnectSeconds.
  ///
  /// In en, this message translates to:
  /// **'Reconnect delay'**
  String get reconnectSeconds;

  /// No description provided for @reconnectSecondsDesc.
  ///
  /// In en, this message translates to:
  /// **'How long to wait after a drop before trying again'**
  String get reconnectSecondsDesc;

  /// No description provided for @wgKeepalive.
  ///
  /// In en, this message translates to:
  /// **'Keep-alive interval'**
  String get wgKeepalive;

  /// No description provided for @wgKeepaliveDesc.
  ///
  /// In en, this message translates to:
  /// **'Send a small packet every few seconds so the connection stays open'**
  String get wgKeepaliveDesc;

  /// No description provided for @wgProfileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry other profiles'**
  String get wgProfileRetry;

  /// No description provided for @wgProfileRetryDesc.
  ///
  /// In en, this message translates to:
  /// **'Try other obfuscation profiles while scanning'**
  String get wgProfileRetryDesc;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get tabHome;

  /// No description provided for @slideToConnect.
  ///
  /// In en, this message translates to:
  /// **'Slide to connect'**
  String get slideToConnect;

  /// No description provided for @releaseToConnect.
  ///
  /// In en, this message translates to:
  /// **'Release to connect'**
  String get releaseToConnect;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'App repository'**
  String get aboutApp;

  /// No description provided for @aboutCoreRepo.
  ///
  /// In en, this message translates to:
  /// **'Core repository'**
  String get aboutCoreRepo;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'Built on'**
  String get aboutCredits;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'Oblivion is the app by bepass-org. The tunnel engine is Aether by Cluvex Studio.'**
  String get aboutFooter;

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectAction;

  /// No description provided for @disconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// No description provided for @tunnelModeSection.
  ///
  /// In en, this message translates to:
  /// **'Tunnel device'**
  String get tunnelModeSection;

  /// No description provided for @tunnelInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface name'**
  String get tunnelInterface;

  /// No description provided for @tunnelInterfaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Name of the virtual network card'**
  String get tunnelInterfaceDesc;

  /// No description provided for @tunnelMtu.
  ///
  /// In en, this message translates to:
  /// **'MTU'**
  String get tunnelMtu;

  /// No description provided for @tunnelMtuDesc.
  ///
  /// In en, this message translates to:
  /// **'Packet size. Lower it if the connection feels slow'**
  String get tunnelMtuDesc;

  /// No description provided for @tunnelDeviceState.
  ///
  /// In en, this message translates to:
  /// **'Device state'**
  String get tunnelDeviceState;

  /// No description provided for @tunnelDeviceEmbedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get tunnelDeviceEmbedded;

  /// No description provided for @tunnelDeviceMissing.
  ///
  /// In en, this message translates to:
  /// **'Not embedded'**
  String get tunnelDeviceMissing;

  /// No description provided for @tunnelNeedsPrivileges.
  ///
  /// In en, this message translates to:
  /// **'Needs elevated privileges'**
  String get tunnelNeedsPrivileges;

  /// No description provided for @tunnelReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get tunnelReady;

  /// No description provided for @tunnelModeActive.
  ///
  /// In en, this message translates to:
  /// **'Full device tunnel'**
  String get tunnelModeActive;

  /// No description provided for @tunnelModeProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy only'**
  String get tunnelModeProxy;

  /// No description provided for @logsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logsAll;

  /// No description provided for @logsSourceAether.
  ///
  /// In en, this message translates to:
  /// **'Aether'**
  String get logsSourceAether;

  /// No description provided for @logsSourceHev.
  ///
  /// In en, this message translates to:
  /// **'Tunnel'**
  String get logsSourceHev;

  /// No description provided for @logsFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get logsFilterEmpty;

  /// No description provided for @logsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get logsCopied;

  /// No description provided for @introSlogan.
  ///
  /// In en, this message translates to:
  /// **'Internet for All, or No One'**
  String get introSlogan;

  /// No description provided for @trayShow.
  ///
  /// In en, this message translates to:
  /// **'Show Oblivion'**
  String get trayShow;

  /// No description provided for @trayHide.
  ///
  /// In en, this message translates to:
  /// **'Hide to tray'**
  String get trayHide;

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @trayStageIdle.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get trayStageIdle;

  /// No description provided for @trayStageBusy.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get trayStageBusy;

  /// No description provided for @trayStageActive.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get trayStageActive;

  /// No description provided for @fragmentNeedsHttp2.
  ///
  /// In en, this message translates to:
  /// **'Switches the transport to HTTP/2, the only one that carries a TLS ClientHello'**
  String get fragmentNeedsHttp2;

  /// No description provided for @transportUdp.
  ///
  /// In en, this message translates to:
  /// **'UDP'**
  String get transportUdp;

  /// No description provided for @transportWiw.
  ///
  /// In en, this message translates to:
  /// **'WARP in WARP'**
  String get transportWiw;

  /// No description provided for @dnsOverride.
  ///
  /// In en, this message translates to:
  /// **'Tunnel the resolver'**
  String get dnsOverride;

  /// No description provided for @dnsOverrideDesc.
  ///
  /// In en, this message translates to:
  /// **'Sends DNS through the tunnel instead of your ISP resolver'**
  String get dnsOverrideDesc;

  /// No description provided for @dnsServers.
  ///
  /// In en, this message translates to:
  /// **'Resolver addresses'**
  String get dnsServers;

  /// No description provided for @dnsServersDesc.
  ///
  /// In en, this message translates to:
  /// **'Used while the tunnel is up'**
  String get dnsServersDesc;

  /// No description provided for @switchOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get switchOff;

  /// No description provided for @switchOn.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get switchOn;

  /// No description provided for @chipFullTunnel.
  ///
  /// In en, this message translates to:
  /// **'Full tunnel'**
  String get chipFullTunnel;

  /// No description provided for @chipProxyOnly.
  ///
  /// In en, this message translates to:
  /// **'Proxy only'**
  String get chipProxyOnly;

  /// No description provided for @chipNotProtected.
  ///
  /// In en, this message translates to:
  /// **'Not protected'**
  String get chipNotProtected;

  /// No description provided for @trafficUnprotected.
  ///
  /// In en, this message translates to:
  /// **'your traffic is not protected'**
  String get trafficUnprotected;

  /// No description provided for @sinceLabel.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String sinceLabel(String time);

  /// No description provided for @exitNode.
  ///
  /// In en, this message translates to:
  /// **'Exit node'**
  String get exitNode;

  /// No description provided for @gatewayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gatewayLabel;

  /// No description provided for @gatewayAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Aether picks the fastest clean edge'**
  String get gatewayAutoHint;

  /// No description provided for @metricDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get metricDownload;

  /// No description provided for @metricUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get metricUpload;

  /// No description provided for @metricSocks.
  ///
  /// In en, this message translates to:
  /// **'SOCKS5'**
  String get metricSocks;

  /// No description provided for @unitPort.
  ///
  /// In en, this message translates to:
  /// **'port'**
  String get unitPort;

  /// No description provided for @mapYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get mapYou;

  /// No description provided for @mapExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get mapExit;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Aether core · {version}'**
  String settingsSubtitle(String version);

  /// No description provided for @fullTunnelDesc.
  ///
  /// In en, this message translates to:
  /// **'Route every app, not just the SOCKS5 port'**
  String get fullTunnelDesc;

  /// No description provided for @sectionDeviceTunnel.
  ///
  /// In en, this message translates to:
  /// **'Device tunnel'**
  String get sectionDeviceTunnel;

  /// No description provided for @sectionDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get sectionDevice;

  /// No description provided for @logsLive.
  ///
  /// In en, this message translates to:
  /// **'live from the core'**
  String get logsLive;

  /// No description provided for @aboutInMemory.
  ///
  /// In en, this message translates to:
  /// **'In memory of'**
  String get aboutInMemory;

  /// No description provided for @aboutHev.
  ///
  /// In en, this message translates to:
  /// **'hev-socks5-tunnel'**
  String get aboutHev;

  /// No description provided for @aboutHevDesc.
  ///
  /// In en, this message translates to:
  /// **'the tun device that carries your packets'**
  String get aboutHevDesc;

  /// No description provided for @aboutAppSummary.
  ///
  /// In en, this message translates to:
  /// **'app {app} · core aether {core}'**
  String aboutAppSummary(String app, String core);

  /// No description provided for @introHeadline.
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get introHeadline;

  /// No description provided for @introBody.
  ///
  /// In en, this message translates to:
  /// **'Oblivion routes your traffic through the Aether core, so the network you are on cannot read or shape it.'**
  String get introBody;

  /// No description provided for @introFeatureTunnelTitle.
  ///
  /// In en, this message translates to:
  /// **'MASQUE over QUIC'**
  String get introFeatureTunnelTitle;

  /// No description provided for @introFeatureTunnelBody.
  ///
  /// In en, this message translates to:
  /// **'A tunnel that looks like ordinary HTTPS traffic.'**
  String get introFeatureTunnelBody;

  /// No description provided for @introFeatureAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to sign up for'**
  String get introFeatureAccountTitle;

  /// No description provided for @introFeatureAccountBody.
  ///
  /// In en, this message translates to:
  /// **'A dedicated identity is provisioned on first launch.'**
  String get introFeatureAccountBody;

  /// No description provided for @introFeatureControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what goes through'**
  String get introFeatureControlTitle;

  /// No description provided for @introFeatureControlBody.
  ///
  /// In en, this message translates to:
  /// **'Split tunnel, custom resolver, per protocol control.'**
  String get introFeatureControlBody;

  /// No description provided for @introGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introGetStarted;

  /// No description provided for @introFooter.
  ///
  /// In en, this message translates to:
  /// **'Free and open source · GPL-3.0'**
  String get introFooter;

  /// No description provided for @splitHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apps listed here bypass the tunnel entirely'**
  String get splitHeaderSubtitle;

  /// No description provided for @splitBypassCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apps bypass the tunnel'**
  String splitBypassCount(String count);

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @geoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'location could not be detected'**
  String get geoUnavailable;

  /// No description provided for @routingMode.
  ///
  /// In en, this message translates to:
  /// **'Routing mode'**
  String get routingMode;

  /// No description provided for @routingSocks.
  ///
  /// In en, this message translates to:
  /// **'SOCKS5 only'**
  String get routingSocks;

  /// No description provided for @routingSocksDesc.
  ///
  /// In en, this message translates to:
  /// **'Only apps you point at the local port go through the tunnel'**
  String get routingSocksDesc;

  /// No description provided for @routingSystem.
  ///
  /// In en, this message translates to:
  /// **'System proxy'**
  String get routingSystem;

  /// No description provided for @routingSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Sets the desktop proxy for every app, no admin rights needed'**
  String get routingSystemDesc;

  /// No description provided for @routingTunnelDesc.
  ///
  /// In en, this message translates to:
  /// **'Routes every packet of the device, needs administrator rights'**
  String get routingTunnelDesc;

  /// No description provided for @chipSystemProxy.
  ///
  /// In en, this message translates to:
  /// **'System proxy'**
  String get chipSystemProxy;

  /// No description provided for @chipSocksOnly.
  ///
  /// In en, this message translates to:
  /// **'SOCKS only'**
  String get chipSocksOnly;

  /// No description provided for @scannerOff.
  ///
  /// In en, this message translates to:
  /// **'Scanner off, your gateway is used directly'**
  String get scannerOff;

  /// No description provided for @endpointManualHint.
  ///
  /// In en, this message translates to:
  /// **'Set a gateway to skip scanning entirely'**
  String get endpointManualHint;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Tunnel status'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Shows whether the tunnel is up and lets you disconnect'**
  String get notificationChannelDesc;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Oblivion needs a notification to keep the tunnel alive in the background'**
  String get notificationPermissionBody;

  /// No description provided for @coreEngine.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get coreEngine;

  /// No description provided for @coreEngineDesc.
  ///
  /// In en, this message translates to:
  /// **'Which tunnel engine to run'**
  String get coreEngineDesc;

  /// No description provided for @coreAether.
  ///
  /// In en, this message translates to:
  /// **'Aether'**
  String get coreAether;

  /// No description provided for @coreAetherDesc.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare WARP and MASQUE'**
  String get coreAetherDesc;

  /// No description provided for @corePsiphon.
  ///
  /// In en, this message translates to:
  /// **'Psiphon'**
  String get corePsiphon;

  /// No description provided for @corePsiphonDesc.
  ///
  /// In en, this message translates to:
  /// **'Psiphon network with CDN fronting'**
  String get corePsiphonDesc;

  /// No description provided for @psiphonSettings.
  ///
  /// In en, this message translates to:
  /// **'Psiphon'**
  String get psiphonSettings;

  /// No description provided for @psiphonCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get psiphonCountry;

  /// No description provided for @psiphonCountryAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get psiphonCountryAuto;

  /// No description provided for @psiphonCountryDesc.
  ///
  /// In en, this message translates to:
  /// **'Where traffic leaves the Psiphon network'**
  String get psiphonCountryDesc;

  /// No description provided for @psiphonMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get psiphonMode;

  /// No description provided for @psiphonModeCdn.
  ///
  /// In en, this message translates to:
  /// **'CDN fronting'**
  String get psiphonModeCdn;

  /// No description provided for @psiphonModeCdnDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach servers through CDN edges'**
  String get psiphonModeCdnDesc;

  /// No description provided for @psiphonModeConduit.
  ///
  /// In en, this message translates to:
  /// **'Conduit'**
  String get psiphonModeConduit;

  /// No description provided for @psiphonModeConduitDesc.
  ///
  /// In en, this message translates to:
  /// **'Route through volunteer in-proxy peers'**
  String get psiphonModeConduitDesc;

  /// No description provided for @psiphonModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get psiphonModeAuto;

  /// No description provided for @psiphonModeAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Let Psiphon pick any protocol it can reach'**
  String get psiphonModeAutoDesc;

  /// No description provided for @psiphonModeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get psiphonModeDirect;

  /// No description provided for @psiphonModeDirectDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect straight to Psiphon servers'**
  String get psiphonModeDirectDesc;

  /// No description provided for @psiphonCdnFronting.
  ///
  /// In en, this message translates to:
  /// **'CDN fronting'**
  String get psiphonCdnFronting;

  /// No description provided for @psiphonCdnIps.
  ///
  /// In en, this message translates to:
  /// **'Edge addresses'**
  String get psiphonCdnIps;

  /// No description provided for @psiphonCdnIpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Extra IPv4 addresses or CIDR ranges to scan, one per line'**
  String get psiphonCdnIpsDesc;

  /// No description provided for @psiphonCdnSni.
  ///
  /// In en, this message translates to:
  /// **'SNI names'**
  String get psiphonCdnSni;

  /// No description provided for @psiphonCdnSniDesc.
  ///
  /// In en, this message translates to:
  /// **'Domain names to present in TLS, one per line'**
  String get psiphonCdnSniDesc;

  /// No description provided for @psiphonConduitPeers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get psiphonConduitPeers;

  /// No description provided for @psiphonConduitPeersAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get psiphonConduitPeersAuto;

  /// No description provided for @psiphonConduitPeersAutoDesc.
  ///
  /// In en, this message translates to:
  /// **'Prefer private peers, fall back to public ones'**
  String get psiphonConduitPeersAutoDesc;

  /// No description provided for @psiphonConduitPeersPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private only'**
  String get psiphonConduitPeersPrivate;

  /// No description provided for @psiphonConduitPeersPrivateDesc.
  ///
  /// In en, this message translates to:
  /// **'Only peers paired with this build'**
  String get psiphonConduitPeersPrivateDesc;

  /// No description provided for @psiphonConduitPeersPublic.
  ///
  /// In en, this message translates to:
  /// **'Public only'**
  String get psiphonConduitPeersPublic;

  /// No description provided for @psiphonConduitPeersPublicDesc.
  ///
  /// In en, this message translates to:
  /// **'Only volunteer peers open to everyone'**
  String get psiphonConduitPeersPublicDesc;

  /// No description provided for @psiphonRejectCensoredPeers.
  ///
  /// In en, this message translates to:
  /// **'Skip censored regions'**
  String get psiphonRejectCensoredPeers;

  /// No description provided for @psiphonRejectCensoredPeersDesc.
  ///
  /// In en, this message translates to:
  /// **'Refuse peers hosted in heavily censored countries'**
  String get psiphonRejectCensoredPeersDesc;

  /// No description provided for @psiphonUnprovisioned.
  ///
  /// In en, this message translates to:
  /// **'This build carries no Psiphon credentials, so the Psiphon core cannot connect'**
  String get psiphonUnprovisioned;

  /// No description provided for @psiphonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Psiphon settings apply only when the Psiphon core is selected'**
  String get psiphonNotAvailable;

  /// No description provided for @aetherOnlySection.
  ///
  /// In en, this message translates to:
  /// **'These settings apply to the Aether core'**
  String get aetherOnlySection;

  /// No description provided for @fastFirstConnect.
  ///
  /// In en, this message translates to:
  /// **'Fast first connect'**
  String get fastFirstConnect;

  /// No description provided for @fastFirstConnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Try a plain connection first, then fall back to obfuscation'**
  String get fastFirstConnectDesc;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'fa':
      return L10nFa();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
