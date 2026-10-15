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
  String get appTagline => 'اینترنت آزاد برای همه، یا هیچ‌کس';

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
  String get renewKeys => 'گرفتن کلیدهای تازه WARP';

  @override
  String get renewKeysDesc =>
      'هویت‌های تازه WARP ثبت می‌شوند و جای هویت‌های فعلی را می‌گیرند';

  @override
  String get renewKeysWhich => 'کدام کلیدها عوض شوند؛ بقیه همان‌طور می‌مانند';

  @override
  String get renewKeysRunning =>
      'کلیدهای تازه در WARP ثبت می‌شوند. تا همه کلیدهای تازه آماده نشوند، کلیدهای فعلی سر جایشان می‌مانند';

  @override
  String get keyKindAll => 'همه کلیدها';

  @override
  String get keysRenewed =>
      'کلیدهای تازه جایگزین شدند و از اتصال بعدی استفاده می‌شوند';

  @override
  String keysNotRenewed(String reason) {
    return 'کلیدهای فعلی دست نخوردند. $reason';
  }

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
      'وایرگارد داخل مسک، برای خروجی بیرون از کشور خودتان';

  @override
  String get protocolGoolClassic => 'Gool کلاسیک';

  @override
  String get protocolGoolClassicDesc => 'وارپ داخل وارپ، با دو هاپ وایرگارد';

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
  String get splitTunnelWhitelist => 'فقط انتخاب‌شده‌ها';

  @override
  String get splitTunnelWhitelistDesc =>
      'فقط برنامه‌هایی که انتخاب می‌کنید از تونل رد می‌شوند، بقیه مستقیم می‌روند';

  @override
  String splitAllowCount(String count) {
    return '$count برنامه از تونل رد می‌شوند';
  }

  @override
  String get splitAllowEmpty =>
      'دست‌کم یک برنامه انتخاب کنید، وگرنه هیچ ترافیکی از تونل رد نمی‌شود';

  @override
  String get splitTunnelPick => 'کدام برنامه‌ها';

  @override
  String get showSystemApps => 'نمایش اپ‌های سیستمی';

  @override
  String get searchApps => 'جست‌وجوی اپ';

  @override
  String get fragment => 'تکه‌تکه فرستادن';

  @override
  String get fragmentDesc =>
      'سلام TLS را تکه‌تکه می‌فرستد تا فیلترینگ نتواند نام سرور را بخواند: در درخواست‌های API وارپ با هر پروتکلی، و در مسک روی HTTP/2';

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
  String get obfuscationOffDesc => 'بدون تغییر شکل، سریع‌ترین دست‌دادن';

  @override
  String get obfuscationLightDesc =>
      'دست‌کاری سبک، برای شبکه‌هایی که سخت‌گیر نیستند';

  @override
  String get obfuscationBalancedDesc =>
      'انتخاب معمول، روی بیشتر شبکه‌ها کار می‌کند';

  @override
  String get obfuscationAggressiveDesc =>
      'سنگین‌ترین تغییر شکل، برای شبکه‌های سخت‌گیر';

  @override
  String get obfuscationAuto => 'خودکار';

  @override
  String get obfuscationAutoDesc =>
      'انتخاب با هسته: firewall برای مسک، balanced برای وایرگارد';

  @override
  String get ipV4Desc => 'فقط از راه IPv4 به دروازه‌ها وصل شو';

  @override
  String get ipV6Desc => 'فقط از راه IPv6 به دروازه‌ها وصل شو';

  @override
  String get ipDualDesc => 'هر دو را امتحان کن و هرکدام جواب داد نگه دار';

  @override
  String get logLevelErrorDesc => 'فقط چیزی که خراب شده';

  @override
  String get logLevelWarnDesc => 'خطاها و هشدارها';

  @override
  String get logLevelInfoDesc => 'انتخاب معمول، هر مرحله یک خط';

  @override
  String get logLevelDebugDesc => 'هرچه هسته انجام می‌دهد، برای ردیابی یک مشکل';

  @override
  String get logLevelTraceDesc => 'تصمیم تک‌تک بسته‌ها، بسیار پرحرف';

  @override
  String get perfAutoDesc => 'متناسب با دستگاهی که برنامه روی آن اجرا می‌شود';

  @override
  String get perfLowDesc => 'کوچک‌ترین بافرها، سبک برای گوشی قدیمی';

  @override
  String get perfMediumDesc => 'حد وسط برای سخت‌افزار معمولی';

  @override
  String get perfHighDesc => 'بزرگ‌ترین بافرها، سریع‌ترین روی دستگاه قوی';

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
  String get wiwSection => 'مسیرهای Gool کلاسیک';

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
      'در Gool کلاسیک استفاده نمی‌شود؛ به‌جایش دو مسیر را نام ببرید.';

  @override
  String get goolPeer => 'سرور وایرگارد Gool';

  @override
  String get goolPeerDesc =>
      'سرور وایرگاردی که Gool داخل تونل به آن وصل می‌شود. خالی بگذارید تا همان سروری که در ثبت‌نامش آمده با پورت ۲۴۰۸ استفاده شود';

  @override
  String get mimInner => 'هاپ درونی مسک در مسک';

  @override
  String get mimInnerDesc =>
      'لبه‌ای که تونل مسک درونی از راه تونل بیرونی به آن می‌رود. خالی بگذارید تا هسته خودش انتخاب کند';

  @override
  String get ech => 'پنهان‌سازی نام سرور (ECH)';

  @override
  String get echDesc =>
      'نام سرور را در دست‌دهی مسک و درخواست‌های API وارپ رمز می‌کند. اگر کلید ECH پیدا نشود، به‌جای نشان دادن نام، اتصال برقرار نمی‌شود';

  @override
  String get echKeyMissing =>
      'ECH روشن است ولی هیچ کلید ECH قابل استفاده‌ای پیدا نشد. اتصال متوقف شد تا نام سرور به‌صورت آشکار فرستاده نشود';

  @override
  String get fragmentSize => 'اندازه قطعه';

  @override
  String get fragmentDelay => 'تأخیر قطعه';

  @override
  String get rangeHint => 'یک عدد یا یک بازه مثل ۸-۱۶';

  @override
  String get tlsGroups => 'گروه‌های کلید TLS';

  @override
  String get tlsGroupsDesc => 'گروه‌های کلیدی که در هندشیک پیشنهاد می‌شود';

  @override
  String get tlsFingerprint => 'اثر انگشت TLS';

  @override
  String get tlsFingerprintDesc =>
      'سلام TLS با مجموعه‌رمزها و GREASE شبیه کدام برنامه باشد';

  @override
  String get fingerprintChrome => 'کروم';

  @override
  String get fingerprintFirefox => 'فایرفاکس';

  @override
  String get fingerprintSemiPython => 'پایتون (نزدیک)';

  @override
  String get fingerprintGo => 'Go';

  @override
  String get fingerprintCustom => 'دلخواه';

  @override
  String get fingerprintCustomDesc =>
      'رمزهای TLS 1.2 و تنظیم GREASE دلخواه خودتان در پایین';

  @override
  String get masqueSni => 'نام سرور مسک (SNI)';

  @override
  String get masqueSniDesc =>
      'نامی که دست‌دهی مسک به شبکه نشان می‌دهد. همان نامی که انتخاب کنید در هر اتصال عیناً فرستاده می‌شود';

  @override
  String get masqueSniDefaultDesc =>
      'پیش‌فرض. شبیه باز کردن سایت خود کلادفلر است';

  @override
  String get masqueSniWarpDesc =>
      'همان نامی که برنامهٔ رسمی وارپ می‌فرستد. بعضی شبکه‌ها آن را می‌بندند';

  @override
  String get masqueSniCustom => 'نام دلخواه';

  @override
  String get masqueSniCustomDesc =>
      'هر نام دامنه‌ای بنویسید؛ دقیقاً همان‌طور که نوشته‌اید فرستاده می‌شود';

  @override
  String get serverNameRefusal =>
      'یک نام دامنه مثل www.cloudflare.com بنویسید، نه نشانی IP';

  @override
  String get echDns => 'سرور DNS کلید ECH';

  @override
  String get echDnsDesc =>
      'جایی که کلید ECH از آن پرسیده می‌شود: udp://ip، tcp://ip یا یک نشانی DNS-over-HTTPS با https:// که می‌تواند با @address= و @sni= تمام شود. خالی یعنی udp://1.1.1.1';

  @override
  String get echDnsRefusal =>
      'به شکل udp://ip، tcp://ip یا یک نشانی https:// بنویسید';

  @override
  String get echDomain => 'دامنهٔ کلید ECH';

  @override
  String get echDomainDesc =>
      'دامنه‌ای که کلید ECH آن به کار می‌رود. خالی یعنی cloudflare-ech.com';

  @override
  String get domainRefusal => 'یک نام دامنه بنویسید';

  @override
  String get tlsCiphers => 'رمزهای TLS 1.2';

  @override
  String get tlsCiphersDesc =>
      'مجموعه‌رمزهایی که بعد از رمزهای TLS 1.3 پیشنهاد می‌شوند، با دونقطه جدا شده. خالی یعنی فهرست کروم. HTTP/3 فقط TLS 1.3 دارد';

  @override
  String get tlsCiphersRefusal => 'نام رمزها را با دونقطه جدا کنید';

  @override
  String get grease => 'ارسال GREASE';

  @override
  String get greaseDesc =>
      'مقدارهای تصادفی GREASE را مثل کروم می‌فرستد تا دست‌دهی شبیه مرورگر باشد. فقط اگر شبکه آن را رد می‌کند خاموشش کنید';

  @override
  String get apiAddress => 'نشانی API وارپ';

  @override
  String get apiAddressDesc =>
      'جایی که درخواست‌های ثبت‌نام و کلید به آن می‌روند: یک نشانی IP یا دامنه، و اگر پورت ۴۴۳ نیست همراه پورت. نام api.cloudflareclient.com در دست‌دهی می‌ماند. خالی بگذارید تا مستقیم وصل شود';

  @override
  String get apiAddressRefusal =>
      'یک نشانی IP یا دامنه بنویسید، با پورت دلخواه مثل 188.114.97.6:443';

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
  String get tunnelMtuDesc =>
      'بزرگ‌ترین بسته‌ای که تونل سالم رد می‌کند. بین 1280 تا 9000';

  @override
  String tunnelMtuMeasured(String path) {
    return 'مسیر اندازه‌گیری‌شده: $path بایت';
  }

  @override
  String get mtuOptimize => 'پیدا کردن بهترین MTU';

  @override
  String get mtuOptimizeDesc =>
      'اینترنت شما واقعاً اندازه‌گیری می‌شود و بزرگ‌ترین بسته‌ای که سالم رد شود انتخاب می‌گردد';

  @override
  String get mtuOptimizeTitle => 'بهینه‌سازی MTU';

  @override
  String get mtuOptimizeMeasuring => 'در حال اندازه‌گیری اتصال شما';

  @override
  String get mtuOptimizeHint =>
      'چند بسته‌ی کوچک آزمایشی به سرورهای عمومی فرستاده می‌شود. چند ثانیه طول می‌کشد.';

  @override
  String get mtuOptimizeLink => 'لینک محلی';

  @override
  String get mtuOptimizePath => 'مسیر اینترنت';

  @override
  String get mtuOptimizeOverhead => 'سربار تونل';

  @override
  String get mtuOptimizeTransport => 'ترابری';

  @override
  String get mtuOptimizeResult => 'بهترین MTU';

  @override
  String get mtuOptimizeCore => 'اندازه‌ی بسته‌ی هسته';

  @override
  String get mtuOptimizeApply => 'اعمال';

  @override
  String get mtuOptimizeRetry => 'اندازه‌گیری دوباره';

  @override
  String get mtuOptimizeUnchanged =>
      'MTU شما همین حالا هم برای این شبکه بهترین مقدار است';

  @override
  String get mtuOptimizeNarrow =>
      'این شبکه فقط بسته‌های کوچک را رد می‌کند، پس تونل هم‌اندازه‌ی آن تنظیم شد';

  @override
  String get mtuOptimizeTight =>
      'این مسیر حتی برای دست‌دادن MASQUE هم تنگ است. اگر تونل بالا نیامد HTTP/2 یا وایرگارد را امتحان کنید.';

  @override
  String get mtuOptimizeBusy =>
      'اول قطع کنید تا اندازه‌گیری شبکه‌ی واقعی شما را ببیند، نه خود تونل را';

  @override
  String get mtuOptimizeFailed => 'اندازه‌گیری کامل نشد';

  @override
  String get mtuOptimizeFailedUnreachable =>
      'هیچ پاسخی برنگشت. ممکن است شبکه UDP را بسته باشد یا اینترنت وصل نباشد.';

  @override
  String get mtuOptimizeFailedDf =>
      'این دستگاه اجازه نداد بسته‌ها بدون تکه‌شدن فرستاده شوند، پس مسیر اینجا قابل اندازه‌گیری نیست.';

  @override
  String get mtuOptimizeFailedSocket =>
      'برنامه نتوانست سوکتی برای اندازه‌گیری باز کند';

  @override
  String get mtuOptimizePartial =>
      'زمان اندازه‌گیری تمام شد، پس مقدار زیر یک کف مطمئن است';

  @override
  String mtuRangeRefusal(String min, String max) {
    return 'عددی بین $min و $max وارد کنید';
  }

  @override
  String portRangeRefusal(String min, String max) {
    return 'پورتی بین $min و $max وارد کنید';
  }

  @override
  String secondsRangeRefusal(String min, String max) {
    return 'تعداد ثانیه‌ای بین $min و $max وارد کنید';
  }

  @override
  String get dnsRefusal => 'یک یا دو نشانی IP وارد کنید';

  @override
  String get settingsNeedReconnect => 'برای اثرگذاری دوباره وصل شوید';

  @override
  String get devNote => 'یادداشت توسعه‌دهنده را بخوانید';

  @override
  String get devNoteDesc => 'انتخاب پروتکل روی اینترنت محدود';

  @override
  String get devNoteTitle => 'یادداشت توسعه‌دهنده';

  @override
  String get devNoteIntro =>
      'روی شبکه‌های به‌شدت فیلترشده، و بیش از همه در ایران، پروتکل MASQUE روی HTTP/3 خیلی کم دوام می‌آورد. HTTP/3 روی QUIC سوار است و QUIC یعنی UDP؛ و UDP همان چیزی است که این شبکه‌ها اول از همه محدود یا حذف می‌کنند. اگر خط شما محدود است، از اینجا شروع نکنید.';

  @override
  String get devNoteHttp2Title => 'با HTTP/2 شروع کنید';

  @override
  String get devNoteHttp2Body =>
      'در تنظیمات، روش اتصال را روی HTTP/2 روی TCP بگذارید. این حالت مثل ترافیک معمولی وب دیده می‌شود و روی خط محدود پایدارترین انتخاب است.';

  @override
  String get devNoteWireGuardTitle => 'یا از وایرگارد استفاده کنید';

  @override
  String get devNoteWireGuardBody =>
      'پروتکل را روی WireGuard بگذارید. حواستان به اسکنر باشد: در حالت متعادل جست‌وجو طول می‌کشد، پس کمی صبر کنید و زود نتیجه نگیرید. اگر نتیجه را سریع می‌خواهید، حالت اسکن را روی توربو بگذارید.';

  @override
  String get devNoteGoolTitle => 'Gool با نشانی خارج از کشور';

  @override
  String get devNoteGoolBody =>
      'Gool حالا وایرگارد را داخل مسک می‌برد. هاپ وایرگارد از داخل وارپ زده می‌شود، پس به‌جای نشانی ایران روی نشانی خارجی بیرون می‌آید. Gool همان نوع اتصالی را که انتخاب کنید به کار می‌برد؛ روی خط محدود آن را با HTTP/2 بزنید. وارپ داخل وارپ قدیمی هم با نام Gool کلاسیک در فهرست مانده است.';

  @override
  String get devNoteDismiss => 'متوجه شدم';

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
  String get introSlogan => 'اینترنت آزاد برای همه، یا هیچ‌کس';

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
  String get coreChain => 'سایفون داخل تانل';

  @override
  String get coreChainDesc =>
      'شما، وارپ، سایفون، اینترنت. خروجی سایفون است و شبکه‌ای که سایفون را بسته اصلا آن را نمی‌بیند';

  @override
  String get corePsiphonReverse => 'تانل از داخل سایفون';

  @override
  String get corePsiphonReverseDesc =>
      'شما، سایفون، وارپ، اینترنت. خروجی وارپ است که از یک exit سایفون گرفته می‌شود و شبکه شما اصلا وارپ نمی‌بیند';

  @override
  String get coreTor => 'تور';

  @override
  String get coreTorDesc => 'تور خالی، بدون تانل زیرش';

  @override
  String get coreTorChain => 'تور داخل تانل';

  @override
  String get coreTorChainDesc =>
      'شما، وارپ، تور، اینترنت. خروجی تور است و شبکه‌ای که تور را بسته اصلا آن را نمی‌بیند';

  @override
  String get coreTorReverse => 'تانل از داخل تور';

  @override
  String get coreTorReverseDesc =>
      'شما، تور، وارپ، اینترنت. خروجی وارپ است که از یک exit تور گرفته می‌شود و شبکه شما اصلا وارپ نمی‌بیند';

  @override
  String get chainOrder => 'ترتیب زنجیره';

  @override
  String chainOrderDesc(String transport, String engine) {
    return 'اول $transport وصل می‌شود، بعد $engine از داخل آن بیرون می‌رود.';
  }

  @override
  String chainOrderReverseDesc(String engine) {
    return 'اول $engine وصل می‌شود، بعد وارپ از داخل آن با MASQUE روی HTTP/2 گرفته می‌شود.';
  }

  @override
  String protocolThroughCarrier(String engine) {
    return 'از داخل $engine وارپ فقط روی HTTP/2 گرفته می‌شود، پس وایرگارد و Gool کلاسیک اجرا نمی‌شوند. انتخاب خودتان با هر هستهٔ دیگری برمی‌گردد';
  }

  @override
  String get chainNeedsTcp =>
      'چون از داخل ایثر می‌رود، سایفون فقط پروتکل‌های TCP خود را به کار می‌گیرد.';

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
  String get psiphonCdnSets => 'فهرست‌های لبهٔ داخلی';

  @override
  String get psiphonCdnSetsDesc =>
      'کدام‌یک از فهرست‌های CDN خود سایفون در اسکن fronting امتحان شود، بعد از آدرس‌های لبهٔ خودتان. اگر هیچ‌کدام انتخاب نشود همهٔ فهرست‌ها امتحان می‌شوند، یا اگر آدرس داده‌اید فقط آدرس‌های شما';

  @override
  String get psiphonCdnSetsAll => 'همه';

  @override
  String get psiphonCdnSetsNone => 'فقط آدرس‌های شما';

  @override
  String get psiphonBundledList => 'شروع با فهرست سرورهای همراه برنامه';

  @override
  String get psiphonBundledListDesc =>
      'سایفون با سرورهای همراه برنامه شروع می‌کند تا اتصال اول منتظر دانلود فهرست سرورها نماند';

  @override
  String get psiphonClearData => 'پاک کردن داده‌های سایفون';

  @override
  String get psiphonClearDataDesc =>
      'سرورها و کشورهای خروجی که سایفون یاد گرفته فراموش می‌شوند و دوباره از فهرست همراه برنامه یا یک دانلود تازه شروع می‌کند';

  @override
  String get psiphonClearDataBusy =>
      'اول اتصال را قطع کنید؛ اتصال فعلی از این داده‌ها استفاده می‌کند';

  @override
  String get psiphonClearDataConfirm =>
      'سایفون سرورها و کشورهای خروجی که یاد گرفته را فراموش می‌کند. ادامه می‌دهید؟';

  @override
  String get psiphonDataCleared => 'داده‌های سایفون پاک شد';

  @override
  String get psiphonDataNotCleared => 'داده‌های سایفون پاک نشد';

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
  String get psiphonConduitUnavailable =>
      'این نسخه اعتبارنامه‌ی کاندوئیت ندارد، پس حالت کاندوئیت نمی‌تواند وصل شود';

  @override
  String get psiphonCountryIgnoredOnConduit =>
      'کاندوئیت از راه همیارهای داوطلب وصل می‌شود، پس کشور را خودش انتخاب می‌کند';

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

  @override
  String get protocolMim => 'مسک در مسک';

  @override
  String get protocolMimDesc =>
      'دو هاپ مسک، برای گرفتن آدرس خروج از یک رنج دیگر';

  @override
  String get scanVerified => 'تأییدشده';

  @override
  String get scanVerifiedDesc =>
      'فقط لبه‌هایی که جوابشان سنجیده شده، نه همسایه‌ای که حدس زده شود';

  @override
  String get obfuscationFirewall => 'فایروال';

  @override
  String get obfuscationFirewallDesc =>
      'پیش‌فرض مسک، تنظیم‌شده برای فایروال فیلترکننده';

  @override
  String get obfuscationGfw => 'GFW';

  @override
  String get obfuscationGfwDesc =>
      'پرسروصداترین پروفایل، وقتی هیچ‌چیز دیگری رد نمی‌شود';

  @override
  String get torRelaysTitle => 'منبع بریج';

  @override
  String get torRelaysDesc => 'بریج‌ها از کجا گرفته شوند وقتی شبکه تور را بسته';

  @override
  String get torRelaysAuto => 'بریج‌دی‌بی و رله‌ها';

  @override
  String get torRelaysOnly => 'فقط رله‌ها';

  @override
  String get torRelaysOff => 'فقط بریج‌دی‌بی';

  @override
  String get torBridges => 'پل‌ها';

  @override
  String get torBridgesDesc =>
      'Tor کی سراغ پل‌ها برود؛ پل‌ها Tor را از دید شبکه‌ای که آن را مسدود می‌کند پنهان می‌کنند';

  @override
  String get torBridgesAuto => 'وقتی Tor مسدود است';

  @override
  String get torBridgesFirst => 'از همان اول';

  @override
  String get torBridgesNever => 'هرگز';

  @override
  String get torBridgesOwn => 'پل‌های خودم';

  @override
  String get torBridgeLines => 'خطوط پل';

  @override
  String get torBridgeLinesDesc =>
      'هر خط یک پل، به همان شکل torrc: obfs4 1.2.3.4:443 FINGERPRINT cert=… iat-mode=0';

  @override
  String get torBridgeLinesRefusal => 'دست‌کم یک خط پل بنویسید';

  @override
  String get exitLocTitle => 'کشور خروج';

  @override
  String get exitLocDesc =>
      'تانلی که در کشور ناخواسته بیرون می‌آید را قبول نکن و دوباره وصل شو. خالی یعنی هر کشوری قبول است';

  @override
  String get exitLocHint => '!IR,AZ,RU';

  @override
  String get exitLocRefusal =>
      'کد دوحرفی کشورها را با ویرگول جدا کنید و برای رد کردن، ! را اول بگذارید؛ مثل !IR,RU یا DE,NL';

  @override
  String get findGateway => 'پیدا کردن گیت‌وی';

  @override
  String get findGatewayDesc =>
      'یک بار همین حالا اسکن می‌کند و بهترین گیت‌وی را نگه می‌دارد تا اتصال‌های بعدی بدون اسکن انجام شوند';

  @override
  String get findGatewayRunning =>
      'دنبال گیت‌وی‌ای می‌گردد که روی این شبکه جواب بدهد. ممکن است چند دقیقه طول بکشد';

  @override
  String gatewayFound(String gateway) {
    return '$gateway پیدا شد و حالا گیت‌وی تنظیمات شماست';
  }

  @override
  String gatewayNotFound(String reason) {
    return 'گیت‌وی‌ای پیدا نشد. $reason';
  }

  @override
  String get jobsNeedDisconnect =>
      'اول اتصال را قطع کنید؛ اتصال فعلی از همین کلیدها استفاده می‌کند';

  @override
  String get activeModeLabel => 'حالت';
}
