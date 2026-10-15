import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/tunnel_settings.dart';
import 'tunnel_channel.dart';

class CoreJobResult<T> {
  const CoreJobResult.found(T this.value) : problem = null, cancelled = false;

  const CoreJobResult.failed(String this.problem)
    : value = null,
      cancelled = false;

  const CoreJobResult.cancelled()
    : value = null,
      problem = null,
      cancelled = true;

  final T? value;
  final String? problem;
  final bool cancelled;

  bool get succeeded => value != null;
}

class CoreJobCancel {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;

  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

class IdentityLayout {
  const IdentityLayout(this.wireguard);

  static const IdentityLayout android = IdentityLayout('aether-wg.toml');
  static const IdentityLayout desktop = IdentityLayout('aether.toml');

  static const String base = 'aether.toml';
  static const String masque = 'aether-masque.toml';

  final String wireguard;

  String get wireguardInner => sibling(wireguard, 'secondary');

  String get masqueInner => sibling(masque, 'secondary');

  String get gool => sibling(masque, 'gool');

  List<String> filesOf(WarpKeyKind kind) => switch (kind) {
    WarpKeyKind.all => <String>[
      wireguard,
      wireguardInner,
      masque,
      masqueInner,
      gool,
    ],
    WarpKeyKind.masque => <String>[masque],
    WarpKeyKind.wireguard => <String>[wireguard],
    WarpKeyKind.gool => <String>[masque, gool],
    WarpKeyKind.goolClassic => <String>[wireguard, wireguardInner],
    WarpKeyKind.mim => <String>[masque, masqueInner],
  };

  static String sibling(String name, String suffix) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '$name-$suffix';
    return '${name.substring(0, dot)}-$suffix${name.substring(dot)}';
  }
}

class CoreJobs {
  CoreJobs(
    this._channel, {
    Future<Directory> Function()? support,
    this._binary,
    IdentityLayout? layout,
  }) : _support = support ?? getApplicationSupportDirectory,
       layout =
           layout ??
           (!kIsWeb && Platform.isAndroid
               ? IdentityLayout.android
               : IdentityLayout.desktop);

  final TunnelChannel _channel;
  final Future<Directory> Function() _support;
  final Future<String?> Function()? _binary;
  final IdentityLayout layout;

  static const Duration registrationTimeout = Duration(minutes: 4);
  static const Duration scanTimeout = Duration(minutes: 6);

  static const String _caDirectories =
      '/apex/com.android.conscrypt/cacerts:/system/etc/security/cacerts';

  static final RegExp _ansi = RegExp('\x1B\\[[0-9;]*[A-Za-z]');
  static final RegExp _problem = RegExp(r'^\s*Error:|\[-\]');
  static final RegExp _registered = RegExp(r'identities ready: \S');

  static final RegExp _masqueGateway = RegExp(r'selected MASQUE gateway (\S+)');
  static final RegExp _wireguardEndpoint = RegExp(
    r'selected WireGuard endpoint (\S+)',
  );
  static final RegExp _goolClassicHops = RegExp(
    r'using cloudflare edge (\S+) \(outer\) and (\S+) \(inner\)',
  );
  static final RegExp _mimHops = RegExp(
    r'masque-in-masque ready: (\S+) \(outer\) and (\S+) \(inner\)',
  );
  static final RegExp _goolReady = RegExp(
    r'gool ready: masque (\S+) carries wireguard (\S+)',
  );
  static final RegExp _exitAccepted = RegExp(r'exit location \S+ accepted');
  static final RegExp _exitRejected = RegExp(r'exit location \S+ rejected');

  static bool get supported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS);

  Future<Directory> identityDirectory() async {
    final support = await _support();
    final name = !kIsWeb && Platform.isAndroid ? 'aether' : 'core';
    return Directory('${support.path}${Platform.pathSeparator}$name');
  }

  String _join(Directory directory, String name) =>
      '${directory.path}${Platform.pathSeparator}$name';

  Future<Map<String, String>> _environment(
    Directory identities,
    Map<String, String> extra,
  ) async {
    final environment = <String, String>{
      'AETHER_CONFIG': _join(identities, IdentityLayout.base),
      'AETHER_WG_CONFIG': _join(identities, layout.wireguard),
      'AETHER_MASQUE_CONFIG': _join(identities, IdentityLayout.masque),
      'AETHER_LOG_LEVEL': 'info',
      'OBLIVION_CORE_OWNER': '$pid',
    };
    if (!kIsWeb && Platform.isAndroid) {
      environment['HOME'] = identities.path;
      environment['SSL_CERT_DIR'] = _caDirectories;
      try {
        environment['TMPDIR'] = (await getTemporaryDirectory()).path;
      } on Object {
        environment['TMPDIR'] = identities.path;
      }
    }
    environment.addAll(extra);
    return environment;
  }

  static String cleanLine(String raw) => raw.replaceAll(_ansi, '').trimRight();

  Future<CoreJobResult<T>> run<T extends Object>({
    required List<String> arguments,
    required Directory identities,
    required T? Function(String line) until,
    required Duration timeout,
    Map<String, String> environment = const <String, String>{},
    bool letItFinish = false,
    ValueChanged<String>? onLine,
    CoreJobCancel? cancel,
  }) async {
    final binary = await (_binary?.call() ?? _channel.coreBinary());
    if (binary == null || !File(binary).existsSync()) {
      return const CoreJobResult.failed('the core binary is missing');
    }
    if (cancel?.isCancelled ?? false) return const CoreJobResult.cancelled();

    identities.createSync(recursive: true);
    final Process process;
    try {
      process = await Process.start(
        binary,
        arguments,
        environment: await _environment(identities, environment),
        workingDirectory: identities.path,
      );
    } on ProcessException catch (error) {
      return CoreJobResult.failed(error.message);
    }

    final outcome = Completer<CoreJobResult<T>>();
    String? problem;

    void finish(CoreJobResult<T> result) {
      if (!outcome.isCompleted) outcome.complete(result);
    }

    void handle(String raw) {
      final line = cleanLine(raw);
      if (line.trim().isEmpty) return;
      onLine?.call(line);
      if (_problem.hasMatch(line)) problem = line.trim();
      final value = until(line);
      if (value != null) finish(CoreJobResult<T>.found(value));
    }

    const decoder = Utf8Decoder(allowMalformed: true);
    final output = process.stdout
        .transform(decoder)
        .transform(const LineSplitter())
        .listen(handle);
    final errors = process.stderr
        .transform(decoder)
        .transform(const LineSplitter())
        .listen(handle);
    final drained = Future.wait(<Future<void>>[
      output.asFuture<void>(),
      errors.asFuture<void>(),
    ]).catchError((Object _) => <void>[]);

    unawaited(
      process.exitCode.then((code) async {
        await drained;
        finish(
          CoreJobResult<T>.failed(
            problem ?? 'the core stopped with exit code $code',
          ),
        );
      }),
    );
    final timer = Timer(
      timeout,
      () =>
          finish(CoreJobResult<T>.failed(problem ?? 'the core took too long')),
    );
    unawaited(
      cancel?.whenCancelled.then((_) => finish(CoreJobResult<T>.cancelled())),
    );

    final result = await outcome.future;
    timer.cancel();

    if (result.succeeded && letItFinish) {
      await process.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () => -1,
      );
    }
    process.kill();
    await process.exitCode.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    await output.cancel();
    await errors.cancel();
    return result;
  }

  Future<CoreJobResult<List<String>>> renewKeys(
    TunnelSettings settings,
    WarpKeyKind kind, {
    ValueChanged<String>? onLine,
    CoreJobCancel? cancel,
  }) async {
    final identities = await identityDirectory();
    final renewal = Directory('${identities.path}-renewal');
    try {
      if (renewal.existsSync()) renewal.deleteSync(recursive: true);
      renewal.createSync(recursive: true);

      final result = await run<bool>(
        arguments: settings.toRegistrationArguments(kind),
        identities: renewal,
        until: (line) => _registered.hasMatch(line) ? true : null,
        timeout: registrationTimeout,
        letItFinish: true,
        onLine: onLine,
        cancel: cancel,
      );
      if (result.cancelled) return const CoreJobResult.cancelled();
      if (!result.succeeded) {
        return CoreJobResult.failed(result.problem ?? 'no keys came back');
      }

      final files = layout.filesOf(kind);
      final missing = files
          .where((name) => !_isIdentity(File(_join(renewal, name))))
          .toList();
      if (missing.isNotEmpty) {
        return CoreJobResult.failed('${missing.join(', ')} did not come back');
      }

      identities.createSync(recursive: true);
      for (final name in files) {
        await File(_join(renewal, name)).rename(_join(identities, name));
      }
      return CoreJobResult.found(files);
    } on FileSystemException catch (error) {
      return CoreJobResult.failed(error.message);
    } finally {
      try {
        if (renewal.existsSync()) renewal.deleteSync(recursive: true);
      } on FileSystemException {
        debugPrint('the renewal folder could not be removed');
      }
    }
  }

  static bool _isIdentity(File file) {
    try {
      return file.existsSync() &&
          file.readAsStringSync().contains(
            RegExp(r'^device_id\s*=', multiLine: true),
          );
    } on FileSystemException {
      return false;
    }
  }

  Future<CoreJobResult<GatewayScan>> findGateway(
    TunnelSettings settings, {
    ValueChanged<String>? onLine,
    CoreJobCancel? cancel,
  }) async {
    final socks = await _freePort();
    final http = await _freePort();
    final exitRule = settings.exitLoc.trim();
    return run<GatewayScan>(
      arguments: settings.toScanArguments(
        bindAddress: '127.0.0.1:$socks',
        httpProxyAddress: '127.0.0.1:$http',
      ),
      identities: await identityDirectory(),
      until: gatewayMatcher(
        settings.effectiveProtocol,
        exitRuled: exitRule.isNotEmpty,
      ),
      timeout: scanTimeout,
      environment: <String, String>{'AETHER_EXIT_LOC': ?exitRule.nullIfEmpty},
      onLine: onLine,
      cancel: cancel,
    );
  }

  static Future<int> _freePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  static GatewayScan? Function(String line) gatewayMatcher(
    CoreProtocol protocol, {
    required bool exitRuled,
  }) {
    if (!exitRuled ||
        protocol == CoreProtocol.mim ||
        protocol == CoreProtocol.gool) {
      return (line) => parseGateway(protocol, line);
    }
    GatewayScan? named;
    return (line) {
      final found = parseGateway(protocol, line);
      if (found != null) {
        named = found;
        return null;
      }
      if (_exitAccepted.hasMatch(line)) return named;
      if (_exitRejected.hasMatch(line)) named = null;
      return null;
    };
  }

  static GatewayScan? parseGateway(CoreProtocol protocol, String line) {
    switch (protocol) {
      case CoreProtocol.masque:
        return _single(_masqueGateway.firstMatch(line));
      case CoreProtocol.wireguard:
        return _single(_wireguardEndpoint.firstMatch(line));
      case CoreProtocol.gool:
        return _single(_goolReady.firstMatch(line));
      case CoreProtocol.goolClassic:
        return _pair(_goolClassicHops.firstMatch(line));
      case CoreProtocol.mim:
        return _pair(_mimHops.firstMatch(line));
    }
  }

  static GatewayScan? _single(RegExpMatch? match) {
    final endpoint = endpointOf(match?.group(1));
    return endpoint == null ? null : GatewayScan(endpoint);
  }

  static GatewayScan? _pair(RegExpMatch? match) {
    final outer = endpointOf(match?.group(1));
    final inner = endpointOf(match?.group(2));
    if (outer == null || inner == null) return null;
    return GatewayScan(outer, inner);
  }

  static String? endpointOf(String? text) {
    if (text == null) return null;
    final value = text.trim().replaceAll(RegExp(r'[,;)]+$'), '');
    if (value.startsWith('[')) {
      final close = value.indexOf(']:');
      if (close < 0) return null;
      final host = InternetAddress.tryParse(value.substring(1, close));
      final port = int.tryParse(value.substring(close + 2));
      if (host == null || port == null || port < 1 || port > 65535) return null;
      return '[${host.address}]:$port';
    }
    final separator = value.lastIndexOf(':');
    if (separator <= 0) return null;
    final host = InternetAddress.tryParse(value.substring(0, separator));
    final port = int.tryParse(value.substring(separator + 1));
    if (host == null || port == null || port < 1 || port > 65535) return null;
    return host.type == InternetAddressType.IPv6
        ? '[${host.address}]:$port'
        : '${host.address}:$port';
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
