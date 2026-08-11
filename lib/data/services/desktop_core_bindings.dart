import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _SetCorePathNative = Int32 Function(Pointer<Utf8>);
typedef _SetCorePathDart = int Function(Pointer<Utf8>);

typedef _ConnectNative = Int32 Function(Pointer<Utf8>);
typedef _ConnectDart = int Function(Pointer<Utf8>);

typedef _VoidReturnsIntNative = Int32 Function();
typedef _VoidReturnsIntDart = int Function();

typedef _StringGetterNative = Pointer<Utf8> Function();
typedef _StringGetterDart = Pointer<Utf8> Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class DesktopCoreBindings {
  DesktopCoreBindings._(DynamicLibrary library)
      : _setCorePath =
            library.lookupFunction<_SetCorePathNative, _SetCorePathDart>(
          'oblivion_set_core_path',
        ),
        _connect = library.lookupFunction<_ConnectNative, _ConnectDart>(
          'oblivion_connect',
        ),
        _disconnect =
            library.lookupFunction<_VoidReturnsIntNative, _VoidReturnsIntDart>(
          'oblivion_disconnect',
        ),
        _submitLine = library.lookupFunction<_ConnectNative, _ConnectDart>(
          'oblivion_submit_line',
        ),
        _statusJson =
            library.lookupFunction<_StringGetterNative, _StringGetterDart>(
          'oblivion_status_json',
        ),
        _drainLogs =
            library.lookupFunction<_StringGetterNative, _StringGetterDart>(
          'oblivion_drain_logs',
        ),
        _readLogs =
            library.lookupFunction<_StringGetterNative, _StringGetterDart>(
          'oblivion_read_logs',
        ),
        _clearLogs =
            library.lookupFunction<_VoidReturnsIntNative, _VoidReturnsIntDart>(
          'oblivion_clear_logs',
        ),
        _coreVersion =
            library.lookupFunction<_StringGetterNative, _StringGetterDart>(
          'oblivion_core_version',
        ),
        _tunnelAvailable =
            library.lookupFunction<_VoidReturnsIntNative, _VoidReturnsIntDart>(
          'oblivion_tunnel_available',
        ),
        _isPrivileged =
            library.lookupFunction<_VoidReturnsIntNative, _VoidReturnsIntDart>(
          'oblivion_is_privileged',
        ),
        _freeString =
            library.lookupFunction<_FreeStringNative, _FreeStringDart>(
          'oblivion_string_free',
        );

  final _SetCorePathDart _setCorePath;
  final _ConnectDart _connect;
  final _VoidReturnsIntDart _disconnect;
  final _ConnectDart _submitLine;
  final _StringGetterDart _statusJson;
  final _StringGetterDart _drainLogs;
  final _StringGetterDart _readLogs;
  final _VoidReturnsIntDart _clearLogs;
  final _StringGetterDart _coreVersion;
  final _VoidReturnsIntDart _tunnelAvailable;
  final _VoidReturnsIntDart _isPrivileged;
  final _FreeStringDart _freeString;

  static DesktopCoreBindings? _instance;

  static bool get isSupported =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static DesktopCoreBindings? open() {
    if (!isSupported) return null;
    final existing = _instance;
    if (existing != null) return existing;

    final library = _loadLibrary();
    if (library == null) return null;

    return _instance = DesktopCoreBindings._(library);
  }

  static DynamicLibrary? _loadLibrary() {
    final names = <String>[
      if (Platform.isWindows) 'oblivion_core.dll',
      if (Platform.isLinux) 'liboblivion_core.so',
      if (Platform.isMacOS) 'liboblivion_core.dylib',
    ];

    final executableDir = File(Platform.resolvedExecutable).parent;
    final candidates = <String>[
      for (final name in names) ...<String>[
        name,
        '${executableDir.path}${Platform.pathSeparator}$name',
        '${executableDir.path}${Platform.pathSeparator}lib'
            '${Platform.pathSeparator}$name',
      ],
    ];

    for (final candidate in candidates) {
      try {
        return DynamicLibrary.open(candidate);
      } on ArgumentError {
        continue;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String _consume(Pointer<Utf8> pointer) {
    if (pointer == nullptr) return '';
    try {
      return pointer.toDartString();
    } finally {
      _freeString(pointer);
    }
  }

  bool setCorePath(String path) {
    final native = path.toNativeUtf8();
    try {
      return _setCorePath(native) == 0;
    } finally {
      calloc.free(native);
    }
  }

  bool connect(String payloadJson) {
    final native = payloadJson.toNativeUtf8();
    try {
      return _connect(native) == 0;
    } finally {
      calloc.free(native);
    }
  }

  void disconnect() => _disconnect();

  bool submitLine(String line) {
    final native = line.toNativeUtf8();
    try {
      return _submitLine(native) == 0;
    } finally {
      calloc.free(native);
    }
  }

  String statusJson() => _consume(_statusJson());

  String drainLogs() => _consume(_drainLogs());

  String readLogs() => _consume(_readLogs());

  void clearLogs() => _clearLogs();

  String coreVersion() {
    final value = _consume(_coreVersion());
    return value.isEmpty ? 'unavailable' : value;
  }

  bool get tunnelDeviceAvailable => _tunnelAvailable() == 1;

  bool get isPrivileged => _isPrivileged() == 1;
}
