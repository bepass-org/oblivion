import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/services/psiphon_data.dart';

String _hex(String text) => utf8
    .encode(text)
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();

String _entry(String address, String region) => _hex(
  '$address 443 secret certificate '
  '{"ipAddress":"$address","region":"$region","capabilities":["OSSH"]}',
);

Uint8List _package(String data) => Uint8List.fromList(
  zlib.encode(
    utf8.encode(
      jsonEncode(<String, String>{
        'data': data,
        'signature': 'c2lnbmF0dXJl',
        'signingPublicKeyDigest': 'a2V5',
      }),
    ),
  ),
);

class _Bundle extends CachingAssetBundle {
  _Bundle(this.bytes);

  Uint8List? bytes;

  @override
  Future<ByteData> load(String key) async {
    final value = bytes;
    if (key != PsiphonServerList.asset || value == null) {
      throw StateError('no asset $key');
    }
    return ByteData.sublistView(value);
  }
}

void main() {
  final realList = File('assets/psiphon/servers.dat');

  group('the bundled psiphon list', () {
    test('the entries come out of the package psiphon signs', () {
      final data = '${_entry('1.2.3.4', 'DE')}\n${_entry('5.6.7.8', 'US')}\n';
      expect(PsiphonServerList.entriesOf(_package(data)), data);
    });

    test('a package that does not unpack gives nothing', () {
      expect(PsiphonServerList.entriesOf(<int>[1, 2, 3]), isNull);
      expect(
        PsiphonServerList.entriesOf(zlib.encode(utf8.encode('[1, 2]'))),
        isNull,
      );
      expect(PsiphonServerList.entriesOf(_package('  \n')), isNull);
    });

    test('every entry names the country it leaves from', () {
      final entries = <String>[
        _entry('1.2.3.4', 'DE'),
        _entry('5.6.7.8', 'us'),
        _entry('9.9.9.9', 'DE'),
        _entry('8.8.8.8', 'Germany'),
        'not hex at all',
        '${_entry('7.7.7.7', 'NL')}0',
        _hex('1.1.1.1 443 secret certificate'),
        _hex('2.2.2.2 443 secret certificate {"capabilities":[]}'),
      ].join('\n');

      expect(PsiphonServerList.regionsOf(entries), <String>{'DE', 'US'});
    });

    test('the report of where psiphon can leave from is read off the log', () {
      expect(
        PsiphonServerList.reportedRegions(
          '[2026-10-15T10:36:18.487Z INFO  aether::psiphon] [*] '
          'psiphon can leave from: US CA DE',
        ),
        <String>['US', 'CA', 'DE'],
      );
      expect(
        PsiphonServerList.reportedRegions(
          '[aether] [*] psiphon can leave from: GB',
        ),
        <String>['GB'],
      );
      expect(
        PsiphonServerList.reportedRegions('psiphon can leave from: usa'),
        isNull,
      );
      expect(PsiphonServerList.reportedRegions('[+] psiphon is ready'), isNull);
    });

    test('a changed list has a different version', () {
      final one = _package(_entry('1.2.3.4', 'DE'));
      final other = _package(_entry('1.2.3.5', 'DE'));
      expect(
        PsiphonServerList.versionOf(one),
        PsiphonServerList.versionOf(one),
      );
      expect(
        PsiphonServerList.versionOf(one),
        isNot(PsiphonServerList.versionOf(other)),
      );
    });

    test(
      'the list the build fetched unpacks into servers in many countries',
      () {
        final entries = PsiphonServerList.entriesOf(realList.readAsBytesSync());
        expect(entries, isNotNull);
        final lines = const LineSplitter()
            .convert(entries!)
            .where((line) => line.trim().isNotEmpty);
        expect(lines.length, greaterThan(50));
        final regions = PsiphonServerList.regionsOf(entries);
        expect(regions.length, greaterThan(5));
        expect(regions.every(PsiphonServerList.isCountryCode), isTrue);
      },
      skip: realList.existsSync()
          ? false
          : 'run tools/fetch-psiphon-servers.sh to check the real list',
    );
  });

  group('psiphon data on disk', () {
    late Directory support;

    setUp(() {
      support = Directory.systemTemp.createTempSync('oblivion-psiphon-');
    });

    tearDown(() {
      if (support.existsSync()) support.deleteSync(recursive: true);
    });

    PsiphonData data(_Bundle bundle) =>
        PsiphonData(bundle: bundle, support: () async => support);

    test(
      'the list is unpacked once and kept while it stays the same',
      () async {
        final contents = '${_entry('1.2.3.4', 'DE')}\n';
        final psiphon = data(_Bundle(_package(contents)));

        final path = await psiphon.serverEntries();
        expect(path, isNotNull);
        expect(File(path!).readAsStringSync(), contents);
        expect(path, startsWith(support.path));

        final stamp = File(path).lastModifiedSync();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(await psiphon.serverEntries(), path);
        expect(File(path).lastModifiedSync(), stamp);
      },
    );

    test('a newer list replaces the one unpacked before', () async {
      final bundle = _Bundle(_package('${_entry('1.2.3.4', 'DE')}\n'));
      final psiphon = data(bundle);
      final path = await psiphon.serverEntries();

      final newer = '${_entry('5.6.7.8', 'US')}\n';
      bundle.bytes = _package(newer);
      expect(await psiphon.serverEntries(), path);
      expect(File(path!).readAsStringSync(), newer);
    });

    test('without a bundled list the core is handed nothing', () async {
      expect(await data(_Bundle(null)).serverEntries(), isNull);
      expect(
        await data(_Bundle(Uint8List.fromList(<int>[1, 2, 3]))).serverEntries(),
        isNull,
      );
      expect(await data(_Bundle(null)).bundledRegions(), isEmpty);
    });

    test('the countries of the bundled list are offered', () async {
      final psiphon = data(
        _Bundle(
          _package('${_entry('1.2.3.4', 'JP')}\n${_entry('5.6.7.8', 'ID')}\n'),
        ),
      );
      expect(await psiphon.bundledRegions(), <String>{'ID', 'JP'});
    });

    test('clearing forgets the datastore and the unpacked list', () async {
      final psiphon = data(_Bundle(_package('${_entry('1.2.3.4', 'DE')}\n')));
      final entries = await psiphon.serverEntries();
      final separator = Platform.pathSeparator;
      final datastore = Directory(
        '${support.path}${separator}core${separator}psiphon'
        '${separator}ca.psiphon.PsiphonTunnel.tunnel-core',
      )..createSync(recursive: true);
      File(
        '${datastore.path}${separator}psiphon.boltdb',
      ).writeAsStringSync('x');
      final identity = File(
        '${support.path}${separator}core${separator}aether.toml',
      )..writeAsStringSync('kept');

      expect(await psiphon.clear(), isTrue);

      expect(datastore.parent.existsSync(), isFalse);
      expect(File(entries!).existsSync(), isFalse);
      expect(identity.readAsStringSync(), 'kept');
      expect(await psiphon.serverEntries(), entries);
    });
  });
}
