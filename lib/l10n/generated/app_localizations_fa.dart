// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class L10nFa extends L10n {
  L10nFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'Oblivion';

  @override
  String get appDisplayName => 'اُوبلیویِن';

  @override
  String get appTagline => 'اینترنت برای همه، یا هیچ‌کس';

  @override
  String get introMeaning => 'به معنای «بی‌خبری، فراموشی»';

  @override
  String get introCredit =>
      'با تلاش #یوسف_قبادی و ده‌ها کنشگر شناخته‌شده و ناشناس، برای اینکه دسترسی آزاد به اینترنت حق همه باشد.';

  @override
  String get memorialTitle => 'به یاد کشته‌شدگان ۱۸ و ۱۹ دی';

  @override
  String get memorialBody =>
      'مردمی بی‌سلاح که به دست نیروهای جمهوری اسلامی کشته شدند';

  @override
  String get memorialVow => 'نه می‌بخشیم، نه فراموش می‌کنیم';

  @override
  String get introSegaro => '#سگارو';

  @override
  String get introYousef => '#یوسف_قبادی';

  @override
  String get introContinue => 'ادامه';

  @override
  String get stateDisconnected => 'متصل نیست';

  @override
  String get stateConnecting => 'در حال اتصال';

  @override
  String get stateValidating => 'بررسی سلامت تونل';

  @override
  String get stateConnected => 'متصل';

  @override
  String get stateDisconnecting => 'در حال قطع';

  @override
  String get stateFailed => 'اتصال برقرار نشد';

  @override
  String get tapToConnect => 'برای اتصال بزنید';

  @override
  String get tapToDisconnect => 'برای قطع بزنید';

  @override
  String get yourLocation => 'موقعیت شما';

  @override
  String get exitLocation => 'خروجی اتصال';

  @override
  String get detectingLocation => 'در حال تشخیص موقعیت';

  @override
  String get locationUnknown => 'نامشخص';

  @override
  String get uploaded => 'ارسال';

  @override
  String get downloaded => 'دریافت';

  @override
  String get duration => 'مدت اتصال';

  @override
  String get protocol => 'پروتکل';

  @override
  String get settings => 'تنظیمات';

  @override
  String get logs => 'گزارش‌ها';

  @override
  String get about => 'درباره';

  @override
  String get language => 'زبان';

  @override
  String get theme => 'پوسته';

  @override
  String get themeDark => 'تیره';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get sectionCore => 'هسته';

  @override
  String get sectionNetwork => 'شبکه';

  @override
  String get sectionAdvanced => 'پیشرفته';

  @override
  String get routingTunnelDescMobile => 'همه ترافیک دستگاه از تونل می‌رود';

  @override
  String get tunnelDegraded =>
      'فقط پروکسی محلی روشن است، ترافیک دستگاه از تونل نمی‌رود';

  @override
  String get tunnelDegradedHint =>
      'برای تونل کامل، برنامه باید با دسترسی مدیر اجرا شود';

  @override
  String get zeroTrust => 'حساب سازمانی';

  @override
  String get zeroTrustDesc =>
      'اتصال با اکانت Zero Trust کلادفلر به جای حساب عمومی';

  @override
  String get zeroTrustOff => 'خاموش';

  @override
  String get zeroTrustTeam => 'نام تیم';

  @override
  String get zeroTrustTeamDesc =>
      'همان نامی که در نشانی <team>.cloudflareaccess.com دارید';

  @override
  String get zeroTrustToken => 'توکن ورود';

  @override
  String get zeroTrustTokenDesc =>
      'در مرورگر وارد <team>.cloudflareaccess.com/warp شوید و توکن را اینجا بچسبانید';

  @override
  String get zeroTrustServiceToken => 'توکن سرویس';

  @override
  String get zeroTrustClientId => 'شناسه کلاینت';

  @override
  String get zeroTrustClientSecret => 'رمز کلاینت';

  @override
  String get zeroTrustGateway => 'عبور از گیت‌وی سازمان';

  @override
  String get zeroTrustGatewayDesc =>
      'فیلترینگ و لاگ سازمان اعمال می‌شود. یک واسطه به تونل اضافه می‌کند و گردش شما در وب ثبت می‌شود.';

  @override
  String get zeroTrustReady => 'آماده اتصال';

  @override
  String get zeroTrustNeedsToken =>
      'یک ایمیل، توکن ورود یا توکن سرویس اضافه کنید';

  @override
  String get zeroTrustSet => 'تنظیم شده';

  @override
  String get zeroTrustClear => 'پاک کردن حساب سازمانی';

  @override
  String get zeroTrustEmail => 'نشانی ایمیل';

  @override
  String get zeroTrustEmailDesc =>
      'ساده‌ترین راه ورود. کلادفلر هنگام اتصال یک کد یک‌بارمصرف ایمیل می‌کند و برنامه آن را از شما می‌پرسد.';

  @override
  String get zeroTrustSignIn => 'روش ورود';

  @override
  String get zeroTrustCodeTitle => 'کد ورود';

  @override
  String zeroTrustCodeBody(String email) {
    return 'کدی به $email ایمیل شد. برای کامل شدن ورود آن را وارد کنید.';
  }

  @override
  String get zeroTrustCodeRetry =>
      'این کد پذیرفته نشد. ایمیل را ببینید و دوباره تلاش کنید.';

  @override
  String get zeroTrustCodePlaceholder => 'کد داخل ایمیل';

  @override
  String get zeroTrustCodeSend => 'ورود';

  @override
  String get zeroTrustCodeLost => 'هسته دیگر منتظر کد نیست';

  @override
  String get notificationConnected => 'تونل فعال است';

  @override
  String get notificationConnecting => 'در حال برقراری تونل';

  @override
  String get notificationDisconnect => 'قطع اتصال';

  @override
  String get sectionRules => 'مسیر ترافیک';

  @override
  String get advancedDesc => 'DNS، پورت، مسیر ترافیک و تنظیمات دقیق‌تر';

  @override
  String get ruleBlock => 'سایت‌های مسدود';

  @override
  String get ruleBlockDesc => 'به این آدرس‌ها اجازه باز شدن داده نمی‌شود';

  @override
  String get ruleDirect => 'بدون تونل';

  @override
  String get ruleDirectDesc =>
      'این آدرس‌ها با اینترنت خودتان باز می‌شوند، نه از تونل';

  @override
  String get ruleNone => 'خالی';

  @override
  String get ruleHint =>
      'هر آدرس را در یک خط بنویسید. می‌توانید نام سایت، آدرس آی‌پی یا شماره پورت بدهید.';

  @override
  String get sectionApp => 'برنامه';

  @override
  String get protocolMasque => 'MASQUE';

  @override
  String get protocolMasqueDesc =>
      'ترانسپورت مدرن QUIC/HTTP-3، بهترین گزینه روی شبکه‌های سالم';

  @override
  String get protocolWireGuard => 'WireGuard';

  @override
  String get protocolWireGuardDesc => 'تونل کلاسیک WARP با کمترین سرباز';

  @override
  String get protocolGool => 'Gool';

  @override
  String get protocolGoolDesc =>
      'وارپ داخل وارپ، کندتر ولی سخت‌تر مسدود می‌شود';

  @override
  String get transport => 'روش اتصال';

  @override
  String get transportH3 => 'HTTP/3 روی QUIC';

  @override
  String get transportH3Desc =>
      'سریع‌تر است، ولی شبکه باید UDP را باز گذاشته باشد';

  @override
  String get transportH2 => 'HTTP/2 روی TCP';

  @override
  String get transportH2Desc =>
      'شبیه یک سایت معمولی دیده می‌شود، وقتی UDP بسته است این را بزنید';

  @override
  String get scanMode => 'حالت اسکن';

  @override
  String get scanTurbo => 'توربو';

  @override
  String get scanTurboDesc => 'سریع، اولین گیت‌وی سالم را می‌گیرد';

  @override
  String get scanBalanced => 'متعادل';

  @override
  String get scanBalancedDesc => 'تعادل بین سرعت و پایداری';

  @override
  String get scanThorough => 'کامل';

  @override
  String get scanThoroughDesc => 'جست‌وجوی عمیق‌تر، انتخاب کم‌تأخیرترین';

  @override
  String get scanStealth => 'پنهان';

  @override
  String get scanStealthDesc => 'آرام و صبور، سر و صدای کمتر روی شبکه';

  @override
  String get scanIronclad => 'آیرون‌کلاد';

  @override
  String get scanIroncladDesc =>
      'برای هر کاندید تونل واقعی می‌سازد و درخواست HTTP واقعی می‌فرستد';

  @override
  String get obfuscation => 'مخفی‌سازی';

  @override
  String get obfuscationOff => 'خاموش';

  @override
  String get obfuscationLight => 'سبک';

  @override
  String get obfuscationBalanced => 'متعادل';

  @override
  String get obfuscationAggressive => 'تهاجمی';

  @override
  String get endpoint => 'سرور';

  @override
  String get endpointDesc =>
      'اگر سرور مشخصی می‌خواهید بنویسید، وگرنه خالی بگذارید تا خودش پیدا کند';

  @override
  String get endpointAuto => 'خودکار';

  @override
  String get ipVersion => 'نسخه IP';

  @override
  String get ipV4 => 'IPv4';

  @override
  String get ipV6 => 'IPv6';

  @override
  String get ipDual => 'هر دو';

  @override
  String get socksPort => 'پورت SOCKS5';

  @override
  String get socksPortDesc => 'پورت لوکالی که هسته روی آن گوش می‌دهد';

  @override
  String get allowLan => 'دسترسی از شبکه محلی';

  @override
  String get allowLanDesc =>
      'دستگاه‌های دیگر شبکه هم بتوانند از این پروکسی استفاده کنند';

  @override
  String get proxyOnly => 'فقط حالت پروکسی';

  @override
  String get proxyOnlyDesc => 'بدون گرفتن ترافیک دستگاه، تنها SOCKS5 باز شود';

  @override
  String get splitTunnel => 'تونل انتخابی';

  @override
  String get splitTunnelDesc => 'انتخاب اپ‌هایی که از تونل عبور نکنند';

  @override
  String get splitTunnelDisabled => 'غیرفعال';

  @override
  String get splitTunnelDisabledDesc => 'ترافیک همه اپ‌ها از تونل رد می‌شود';

  @override
  String get splitTunnelBlacklist => 'عبور موارد انتخابی';

  @override
  String get splitTunnelBlacklistDesc =>
      'اپ‌های انتخاب‌شده از تونل رد نمی‌شوند';

  @override
  String get showSystemApps => 'نمایش اپ‌های سیستمی';

  @override
  String get searchApps => 'جست‌وجوی اپ';

  @override
  String get fragment => 'تکه‌تکه فرستادن';

  @override
  String get fragmentDesc =>
      'شروع اتصال را تکه‌تکه می‌فرستد تا فیلترینگ نتواند آن را بشناسد';

  @override
  String get logLevel => 'سطح گزارش';

  @override
  String get logLevelError => 'خطا';

  @override
  String get logLevelWarn => 'هشدار';

  @override
  String get logLevelInfo => 'معمولی';

  @override
  String get logLevelDebug => 'دیباگ';

  @override
  String get logLevelTrace => 'کامل';

  @override
  String get perfProfile => 'پروفایل مصرف منابع';

  @override
  String get perfProfileDesc =>
      'میزان پردازنده و حافظه‌ای که هسته می‌تواند بگیرد';

  @override
  String get perfAuto => 'خودکار';

  @override
  String get perfLow => 'کم';

  @override
  String get perfMedium => 'متوسط';

  @override
  String get perfHigh => 'زیاد';

  @override
  String get quickReconnect => 'اتصال سریع مجدد';

  @override
  String get quickReconnectDesc =>
      'قبل از اسکن کامل، آخرین گیت‌وی سالم را امتحان کن';

  @override
  String get resetSettings => 'بازنشانی تنظیمات';

  @override
  String get resetSettingsDesc => 'برگرداندن همه چیز به حالت پیش‌فرض';

  @override
  String get resetConfirmTitle => 'تنظیمات بازنشانی شود؟';

  @override
  String get resetConfirmBody =>
      'همه تنظیمات به مقدار پیش‌فرض برمی‌گردد. هویت ذخیره‌شده شما حفظ می‌شود.';

  @override
  String get cancel => 'لغو';

  @override
  String get confirm => 'تأیید';

  @override
  String get save => 'ذخیره';

  @override
  String get copyLogs => 'کپی گزارش‌ها';

  @override
  String get clearLogs => 'پاک کردن گزارش‌ها';

  @override
  String get logsEmpty =>
      'هنوز گزارشی نیست. یک بار وصل شوید تا اینجا نمایش داده شود.';

  @override
  String get copiedToClipboard => 'در کلیپ‌بورد کپی شد';

  @override
  String get aboutBody =>
      'اوبلیوین یک برنامه آزاد و متن‌باز برای رسیدن به اینترنت بدون سانسور است. رایگان است و فروش یا استفاده تجاری از آن اجازه ندارد.';

  @override
  String get aboutCore => 'هسته ایتر';

  @override
  String get aboutPsiphonCore => 'هسته سایفون';

  @override
  String get aboutVersion => 'نسخه';

  @override
  String get aboutSource => 'کد منبع';

  @override
  String get aboutLicense => 'مجوز';

  @override
  String get vpnPermissionNeeded => 'برای عبور دادن ترافیک، اجازه VPN لازم است';

  @override
  String get vpnPermissionDenied => 'اجازه داده نشد، تونل نمی‌تواند شروع شود';

  @override
  String get connectionFailedRetry =>
      'تونل برقرار نشد. پروتکل یا حالت اسکن دیگری را امتحان کنید.';

  @override
  String get exitConfirm => 'برای خروج دوباره بازگشت را بزنید';

  @override
  String get notificationTitle => 'اوبلیوین';

  @override
  String get mapAttribution => 'داده‌های نقشه از مشارکت‌کنندگان OpenStreetMap';

  @override
  String get sectionTls => 'TLS و استتار';

  @override
  String get sectionReliability => 'پایداری';

  @override
  String get wgEndpoint => 'سرور وایرگارد';

  @override
  String get wgEndpointDesc => 'خالی بگذارید تا خودش انتخاب کند';

  @override
  String get h2Endpoint => 'سرور HTTP/2';

  @override
  String get h2EndpointDesc => 'سروری که در حالت HTTP/2 استفاده می‌شود';

  @override
  String get wiwSection => 'مسیرهای WARP در WARP';

  @override
  String get wiwSectionDesc =>
      'به‌جای انتظار برای اسکن، دو مسیر را خودتان بدهید.';

  @override
  String get wiwOuter => 'مسیر بیرونی';

  @override
  String get wiwOuterDesc =>
      'همان لبه‌ای که شبکه شما می‌بیند. خالی بگذارید تا اسکن خودش انتخاب کند.';

  @override
  String get wiwInner => 'مسیر درونی';

  @override
  String get wiwInnerDesc =>
      'لبه‌ای که از راه مسیر بیرونی به آن می‌رسیم. خالی بگذارید تا اسکن خودش انتخاب کند.';

  @override
  String get wiwHint =>
      'نشانی و پورت را با هم بنویسید، مثل 162.159.192.1:2408. پورت الزامی است و دو مسیر باید نشانی متفاوت داشته باشند.';

  @override
  String get wiwScanned => 'اسکن خودکار';

  @override
  String get wiwManual => 'دستی';

  @override
  String get wiwInvalidEndpoint =>
      'این یک نشانی و پورت نیست. آن‌ها را با هم بنویسید، مثل 162.159.192.1:2408.';

  @override
  String get wiwSameEdge =>
      'هر دو مسیر به یک لبه اشاره می‌کنند. WARP در WARP به دو نشانی متفاوت نیاز دارد.';

  @override
  String get endpointIgnoredOnGool =>
      'در WARP در WARP استفاده نمی‌شود؛ به‌جایش دو مسیر را نام ببرید.';

  @override
  String get ech => 'پنهان‌سازی نام سایت';

  @override
  String get echDesc =>
      'نام سایتی که به آن وصل می‌شوید را از دید شبکه پنهان می‌کند';

  @override
  String get fragmentSize => 'اندازه قطعه';

  @override
  String get fragmentDelay => 'تأخیر قطعه';

  @override
  String get rangeHint => 'یک عدد یا یک بازه مثل ۱۶-۳۲';

  @override
  String get tlsGroups => 'گروه‌های کلید TLS';

  @override
  String get tlsGroupsDesc => 'گروه‌های کلیدی که در هندشیک پیشنهاد می‌شود';

  @override
  String get dataCheck => 'بررسی عبور داده';

  @override
  String get dataCheckDesc =>
      'تا وقتی داده واقعی رد و بدل نشده، متصل اعلام نکند';

  @override
  String get validateSeconds => 'مهلت بررسی';

  @override
  String get validateSecondsDesc =>
      'چند ثانیه صبر کند تا مطمئن شود تونل کار می‌کند';

  @override
  String get reconnectSeconds => 'تأخیر اتصال مجدد';

  @override
  String get reconnectSecondsDesc =>
      'بعد از قطعی چند ثانیه صبر کند و دوباره وصل شود';

  @override
  String get wgKeepalive => 'فاصله سیگنال زنده‌ماندن';

  @override
  String get wgKeepaliveDesc =>
      'هر چند ثانیه یک بسته کوچک بفرستد تا اتصال باز بماند';

  @override
  String get wgProfileRetry => 'امتحان پروفایل‌های دیگر';

  @override
  String get wgProfileRetryDesc =>
      'در طول اسکن پروفایل‌های مخفی‌سازی دیگر هم امتحان شود';

  @override
  String get tabHome => 'سپر';

  @override
  String get slideToConnect => 'برای اتصال بکشید';

  @override
  String get releaseToConnect => 'رها کنید تا وصل شود';

  @override
  String get aboutApp => 'مخزن برنامه';

  @override
  String get aboutCoreRepo => 'مخزن هسته';

  @override
  String get aboutCredits => 'ساخته‌شده بر پایه';

  @override
  String get aboutFooter =>
      'برنامه اوبلیوین کار bepass-org است و هسته تونل، ایتر ساخته Cluvex Studio.';

  @override
  String get connectAction => 'اتصال';

  @override
  String get disconnectAction => 'قطع اتصال';

  @override
  String get retryAction => 'تلاش دوباره';

  @override
  String get tunnelModeSection => 'تونل دستگاه';

  @override
  String get tunnelInterface => 'نام اینترفیس';

  @override
  String get tunnelInterfaceDesc => 'نام کارت شبکه مجازی';

  @override
  String get tunnelMtu => 'MTU';

  @override
  String get tunnelMtuDesc => 'اندازه بسته‌ها. اگر اتصال کند است کمترش کنید';

  @override
  String get tunnelDeviceState => 'وضعیت دستگاه';

  @override
  String get tunnelDeviceEmbedded => 'تعبیه شده';

  @override
  String get tunnelDeviceMissing => 'تعبیه نشده';

  @override
  String get tunnelNeedsPrivileges => 'نیازمند دسترسی مدیر';

  @override
  String get tunnelReady => 'آماده';

  @override
  String get tunnelModeActive => 'تونل کامل دستگاه';

  @override
  String get tunnelModeProxy => 'تنها پروکسی';

  @override
  String get logsAll => 'همه';

  @override
  String get logsSourceAether => 'Aether';

  @override
  String get logsSourceHev => 'تونل';

  @override
  String get logsFilterEmpty => 'چیزی پیدا نشد';

  @override
  String get logsCopied => 'در کلیپ‌بورد کپی شد';

  @override
  String get introSlogan => 'اینترنت برای همه، یا هیچ‌کس';

  @override
  String get trayShow => 'نمایش اوبلیوین';

  @override
  String get trayHide => 'کوچک‌سازی در نوار';

  @override
  String get trayQuit => 'خروج';

  @override
  String get trayStageIdle => 'قطع';

  @override
  String get trayStageBusy => 'در حال اتصال';

  @override
  String get trayStageActive => 'متصل';

  @override
  String get fragmentNeedsHttp2 => 'فقط در حالت HTTP/2 کار می‌کند';

  @override
  String get transportUdp => 'UDP';

  @override
  String get transportWiw => 'WARP در WARP';

  @override
  String get dnsOverride => 'DNS از داخل تونل';

  @override
  String get dnsOverrideDesc =>
      'درخواست‌های DNS به جای سرور اپراتور، از تونل می‌روند';

  @override
  String get dnsServers => 'سرورهای DNS';

  @override
  String get dnsServersDesc =>
      'وقتی تونل روشن است از این سرورها استفاده می‌شود';

  @override
  String get switchOff => 'خاموش';

  @override
  String get switchOn => 'ایمن';

  @override
  String get chipFullTunnel => 'تونل کامل';

  @override
  String get chipProxyOnly => 'فقط پروکسی';

  @override
  String get chipNotProtected => 'محافظت نشده';

  @override
  String get trafficUnprotected => 'ترافیک شما محافظت نشده است';

  @override
  String sinceLabel(String time) {
    return 'از $time';
  }

  @override
  String get exitNode => 'گره خروج';

  @override
  String get gatewayLabel => 'دروازه';

  @override
  String get gatewayAutoHint =>
      'ایتر سریع‌ترین سرور سالم را خودش انتخاب می‌کند';

  @override
  String get metricDownload => 'دریافت';

  @override
  String get metricUpload => 'ارسال';

  @override
  String get metricSocks => 'SOCKS5';

  @override
  String get unitPort => 'پورت';

  @override
  String get mapYou => 'شما';

  @override
  String get mapExit => 'خروج';

  @override
  String settingsSubtitle(String version) {
    return 'هسته ایتر · $version';
  }

  @override
  String get fullTunnelDesc =>
      'همه برنامه‌ها از تونل می‌روند، نه فقط پورت SOCKS5';

  @override
  String get sectionDeviceTunnel => 'تونل دستگاه';

  @override
  String get sectionDevice => 'دستگاه';

  @override
  String get logsLive => 'زنده از هسته';

  @override
  String get aboutInMemory => 'به یاد';

  @override
  String get aboutHev => 'hev-socks5-tunnel';

  @override
  String get aboutHevDesc => 'دستگاه tun که بسته‌های شما را جابه‌جا می‌کند';

  @override
  String aboutAppSummary(String app, String core) {
    return 'اپ $app · هسته ایتر $core';
  }

  @override
  String get introHeadline => 'پیش‌فرض، خصوصی';

  @override
  String get introBody =>
      'اوبلیوین ترافیک شما را از هسته ایتر می‌برد تا شبکه‌ای که در آن هستید نتواند آن را بخواند یا دستکاری کند.';

  @override
  String get introFeatureTunnelTitle => 'MASQUE روی QUIC';

  @override
  String get introFeatureTunnelBody =>
      'تونلی که شبیه ترافیک معمولی HTTPS دیده می‌شود.';

  @override
  String get introFeatureAccountTitle => 'بدون ثبت‌نام';

  @override
  String get introFeatureAccountBody =>
      'در اولین اجرا یک هویت اختصاصی ساخته می‌شود.';

  @override
  String get introFeatureControlTitle => 'انتخاب مسیر ترافیک';

  @override
  String get introFeatureControlBody =>
      'تونل تفکیکی، DNS دلخواه و کنترل پروتکل.';

  @override
  String get introGetStarted => 'شروع کنیم';

  @override
  String get introFooter => 'آزاد و متن‌باز · GPL-3.0';

  @override
  String get splitHeaderSubtitle =>
      'برنامه‌های این فهرست کامل از تونل خارج می‌شوند';

  @override
  String splitBypassCount(String count) {
    return '$count برنامه از تونل خارج می‌شوند';
  }

  @override
  String get apply => 'اعمال';

  @override
  String get geoUnavailable => 'موقعیت شناسایی نشد';

  @override
  String get routingMode => 'حالت مسیریابی';

  @override
  String get routingSocks => 'فقط SOCKS5';

  @override
  String get routingSocksDesc =>
      'فقط برنامه‌هایی که خودتان به پورت محلی وصل کنید از تونل می‌روند';

  @override
  String get routingSystem => 'پروکسی سیستم';

  @override
  String get routingSystemDesc =>
      'پروکسی را برای همه برنامه‌ها تنظیم می‌کند، به دسترسی مدیر نیاز ندارد';

  @override
  String get routingTunnelDesc =>
      'همه ترافیک دستگاه از تونل می‌رود، به دسترسی مدیر نیاز دارد';

  @override
  String get chipSystemProxy => 'پروکسی سیستم';

  @override
  String get chipSocksOnly => 'فقط SOCKS';

  @override
  String get scannerOff =>
      'جست‌وجو خاموش است و همان سروری که دادید استفاده می‌شود';

  @override
  String get endpointManualHint => 'خالی باشد، خودش بهترین سرور را پیدا می‌کند';

  @override
  String get notificationChannelName => 'وضعیت تونل';

  @override
  String get notificationChannelDesc =>
      'نشان می‌دهد تونل بالاست و امکان قطع کردن می‌دهد';

  @override
  String get notificationPermissionTitle => 'اجازه نوتیفیکیشن';

  @override
  String get notificationPermissionBody =>
      'اوبلیوین برای زنده نگه داشتن تونل در پس‌زمینه به نوتیفیکیشن نیاز دارد';

  @override
  String get coreEngine => 'هسته';

  @override
  String get coreEngineDesc => 'کدام موتور تانل اجرا شود';

  @override
  String get coreAether => 'Aether';

  @override
  String get coreAetherDesc => 'وارپ کلادفلر و MASQUE';

  @override
  String get corePsiphon => 'سایفون';

  @override
  String get corePsiphonDesc => 'شبکه سایفون با CDN fronting';

  @override
  String get psiphonSettings => 'سایفون';

  @override
  String get psiphonCountry => 'کشور';

  @override
  String get psiphonCountryAuto => 'خودکار';

  @override
  String get psiphonCountryDesc =>
      'ترافیک از کدام کشور از شبکه سایفون بیرون بزند';

  @override
  String get psiphonMode => 'حالت';

  @override
  String get psiphonModeCdn => 'CDN fronting';

  @override
  String get psiphonModeCdnDesc => 'رسیدن به سرورها از طریق لبه‌های CDN';

  @override
  String get psiphonModeConduit => 'Conduit';

  @override
  String get psiphonModeConduitDesc => 'عبور از همتاهای داوطلب in-proxy';

  @override
  String get psiphonModeAuto => 'خودکار';

  @override
  String get psiphonModeAutoDesc => 'سایفون خودش هر پروتکلی که برسد انتخاب کند';

  @override
  String get psiphonModeDirect => 'مستقیم';

  @override
  String get psiphonModeDirectDesc => 'اتصال مستقیم به سرورهای سایفون';

  @override
  String get psiphonCdnFronting => 'CDN fronting';

  @override
  String get psiphonCdnIps => 'آدرس‌های لبه';

  @override
  String get psiphonCdnIpsDesc =>
      'آدرس‌های IPv4 یا بازه CIDR برای اسکن، هر خط یکی';

  @override
  String get psiphonCdnSni => 'نام‌های SNI';

  @override
  String get psiphonCdnSniDesc =>
      'نام دامنه‌هایی که در TLS نشان داده شوند، هر خط یکی';

  @override
  String get psiphonConduitPeers => 'همتاها';

  @override
  String get psiphonConduitPeersAuto => 'خودکار';

  @override
  String get psiphonConduitPeersAutoDesc => 'اول همتاهای خصوصی، اگر نشد عمومی';

  @override
  String get psiphonConduitPeersPrivate => 'فقط خصوصی';

  @override
  String get psiphonConduitPeersPrivateDesc =>
      'فقط همتاهایی که با این نسخه جفت شده‌اند';

  @override
  String get psiphonConduitPeersPublic => 'فقط عمومی';

  @override
  String get psiphonConduitPeersPublicDesc =>
      'فقط همتاهای داوطلب که برای همه بازند';

  @override
  String get psiphonRejectCensoredPeers => 'رد کردن مناطق سانسورشده';

  @override
  String get psiphonRejectCensoredPeersDesc =>
      'همتاهایی که در کشورهای پرسانسور میزبانی می‌شوند رد شوند';

  @override
  String get psiphonUnprovisioned =>
      'این نسخه اعتبارنامه سایفون ندارد، پس هسته سایفون نمی‌تواند وصل شود';

  @override
  String get psiphonNotAvailable =>
      'تنظیمات سایفون فقط وقتی هسته سایفون انتخاب شده اعمال می‌شود';

  @override
  String get aetherOnlySection => 'این تنظیمات به هسته Aether مربوط است';

  @override
  String get fastFirstConnect => 'اتصال اول سریع';

  @override
  String get fastFirstConnectDesc =>
      'اول اتصال ساده امتحان شود، اگر نشد سراغ مبهم‌سازی برود';
}
