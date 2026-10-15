import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PsiphonServerList {
  const PsiphonServerList._();

  static const String asset = 'assets/psiphon/servers.dat';

  static final RegExp _leavesFrom = RegExp(
    r'psiphon can leave from: ([A-Z]{2}(?: [A-Z]{2})*)\s*$',
  );

  static final RegExp _countryCode = RegExp(r'^[A-Z]{2}$');

  static bool isCountryCode(String value) => _countryCode.hasMatch(value);

  static String? entriesOf(List<int> packed) {
    try {
      final decoded = jsonDecode(utf8.decode(zlib.decode(packed)));
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! String || data.trim().isEmpty) return null;
      return data;
    } on Object {
      return null;
    }
  }

  static Set<String> regionsOf(String entries) {
    final regions = SplayTreeSet<String>();
    for (final line in const LineSplitter().convert(entries)) {
      final region = _regionOf(line.trim());
      if (region != null) regions.add(region);
    }
    return regions;
  }

  static List<String>? reportedRegions(String line) =>
      _leavesFrom.firstMatch(line)?.group(1)?.split(' ');

  static String? _regionOf(String line) {
    if (line.isEmpty || line.length.isOdd) return null;
    final bytes = Uint8List(line.length ~/ 2);
    for (var index = 0; index < bytes.length; index++) {
      final high = _hexDigit(line.codeUnitAt(2 * index));
      final low = _hexDigit(line.codeUnitAt(2 * index + 1));
      if (high < 0 || low < 0) return null;
      bytes[index] = (high << 4) | low;
    }

    final text = utf8.decode(bytes, allowMalformed: true);
    var start = 0;
    for (var field = 0; field < 4; field++) {
      start = text.indexOf(' ', start);
      if (start < 0) return null;
      start++;
    }

    try {
      final entry = jsonDecode(text.substring(start));
      final region = entry is Map ? entry['region'] : null;
      if (region is! String) return null;
      final code = region.trim().toUpperCase();
      return isCountryCode(code) ? code : null;
    } on FormatException {
      return null;
    }
  }

  static int _hexDigit(int unit) {
    if (unit >= 0x30 && unit <= 0x39) return unit - 0x30;
    final lower = unit | 0x20;
    if (lower >= 0x61 && lower <= 0x66) return lower - 0x61 + 10;
    return -1;
  }

  static String versionOf(Uint8List packed) {
    var hash = 0x811c9dc5;
    for (final byte in packed) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '${packed.length}:${hash.toRadixString(16)}';
  }
}

class PsiphonData {
  PsiphonData({AssetBundle? bundle, Future<Directory> Function()? support})
    : _bundle = bundle ?? rootBundle,
      _support = support ?? getApplicationSupportDirectory;

  static const String entriesName = 'psiphon-servers.txt';
  static const String _stampName = 'psiphon-servers.stamp';

  final AssetBundle _bundle;
  final Future<Directory> Function() _support;

  Future<Uint8List?> _packed() async {
    try {
      final data = await _bundle.load(PsiphonServerList.asset);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on Object {
      return null;
    }
  }

  String _join(Directory directory, String name) =>
      '${directory.path}${Platform.pathSeparator}$name';

  Future<String?> serverEntries() async {
    final packed = await _packed();
    if (packed == null) return null;

    final Directory directory;
    try {
      directory = await _support();
    } on Object {
      return null;
    }

    final entries = File(_join(directory, entriesName));
    final stamp = File(_join(directory, _stampName));
    final version = PsiphonServerList.versionOf(packed);

    try {
      if (entries.existsSync() &&
          stamp.existsSync() &&
          stamp.readAsStringSync() == version) {
        return entries.path;
      }

      final text = await Isolate.run(() => PsiphonServerList.entriesOf(packed));
      if (text == null) return null;

      if (!directory.existsSync()) directory.createSync(recursive: true);
      final fresh = File('${entries.path}.new');
      await fresh.writeAsString(text, flush: true);
      await fresh.rename(entries.path);
      await stamp.writeAsString(version, flush: true);
      return entries.path;
    } on FileSystemException {
      return entries.existsSync() ? entries.path : null;
    }
  }

  Future<Set<String>> bundledRegions() async {
    final packed = await _packed();
    if (packed == null) return const <String>{};
    return Isolate.run(() {
      final entries = PsiphonServerList.entriesOf(packed);
      return entries == null
          ? const <String>{}
          : PsiphonServerList.regionsOf(entries);
    });
  }

  Directory _stateDirectory(Directory support) {
    final separator = Platform.pathSeparator;
    final relative = Platform.isAndroid ? 'psiphon' : 'core${separator}psiphon';
    return Directory('${support.path}$separator$relative');
  }

  Future<bool> clear() async {
    final Directory support;
    try {
      support = await _support();
    } on Object {
      return false;
    }

    final targets = <FileSystemEntity>[
      _stateDirectory(support),
      File(_join(support, entriesName)),
      File(_join(support, _stampName)),
    ];

    var cleared = true;
    for (final target in targets) {
      try {
        if (target.existsSync()) await target.delete(recursive: true);
      } on FileSystemException {
        cleared = false;
      }
    }
    return cleared && targets.every((target) => !target.existsSync());
  }
}
