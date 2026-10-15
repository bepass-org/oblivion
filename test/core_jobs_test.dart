import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';
import 'package:oblivion/data/services/core_jobs.dart';
import 'package:oblivion/data/services/tunnel_channel.dart';

const _masque = TunnelSettings();

String _value(List<String> args, String flag) => args[args.indexOf(flag) + 1];

void main() {
  group('the keys a registration writes', () {
    test('android keeps wireguard in its own file', () {
      const layout = IdentityLayout.android;
      expect(layout.filesOf(WarpKeyKind.wireguard), <String>['aether-wg.toml']);
      expect(layout.filesOf(WarpKeyKind.goolClassic), <String>[
        'aether-wg.toml',
        'aether-wg-secondary.toml',
      ]);
      expect(layout.filesOf(WarpKeyKind.gool), <String>[
        'aether-masque.toml',
        'aether-masque-gool.toml',
      ]);
      expect(layout.filesOf(WarpKeyKind.mim), <String>[
        'aether-masque.toml',
        'aether-masque-secondary.toml',
      ]);
      expect(layout.filesOf(WarpKeyKind.all), hasLength(5));
    });

    test('the desktop keeps wireguard in the base file', () {
      const layout = IdentityLayout.desktop;
      expect(layout.filesOf(WarpKeyKind.wireguard), <String>['aether.toml']);
      expect(layout.filesOf(WarpKeyKind.goolClassic), <String>[
        'aether.toml',
        'aether-secondary.toml',
      ]);
      expect(layout.filesOf(WarpKeyKind.masque), <String>[
        'aether-masque.toml',
      ]);
    });

    test('every protocol asks for its own keys', () {
      expect(WarpKeyKind.of(CoreProtocol.masque), WarpKeyKind.masque);
      expect(WarpKeyKind.of(CoreProtocol.wireguard), WarpKeyKind.wireguard);
      expect(WarpKeyKind.of(CoreProtocol.gool), WarpKeyKind.gool);
      expect(WarpKeyKind.of(CoreProtocol.goolClassic), WarpKeyKind.goolClassic);
      expect(WarpKeyKind.of(CoreProtocol.mim), WarpKeyKind.mim);
      for (final kind in WarpKeyKind.values.skip(1)) {
        expect(CoreProtocol.values.map((p) => p.wire), contains(kind.wire));
      }
    });
  });

  group('the registration run', () {
    test('it registers and dials the api the way the settings say', () {
      final args = const TunnelSettings(
        fragment: true,
        fragmentSize: '8-16',
        echMode: EchMode.auto,
        echDns: 'tcp://1.1.1.1',
        apiAddress: '188.114.97.6:2053',
        tlsFingerprint: TlsFingerprint.firefox,
        endpoint: '162.159.198.1:443',
      ).toRegistrationArguments(WarpKeyKind.mim);

      expect(args.take(2), <String>['--register', 'mim']);
      expect(_value(args, '--log-level'), 'info');
      expect(args, contains('--fragment'));
      expect(_value(args, '--fragment-size'), '8-16');
      expect(_value(args, '--ech'), 'auto');
      expect(_value(args, '--ech-dns'), 'tcp://1.1.1.1');
      expect(_value(args, '--api-address'), '188.114.97.6:2053');
      expect(
        _value(args, '--tls-ciphers'),
        const TunnelSettings(
          tlsFingerprint: TlsFingerprint.firefox,
        ).effectiveTlsCiphers,
      );
      for (final flag in <String>['--bind', '--peer', '--masque', '--scan']) {
        expect(args, isNot(contains(flag)));
      }
    });

    test('a plain run carries only the fingerprint', () {
      final args = _masque.toRegistrationArguments(WarpKeyKind.all);
      expect(args, isNot(contains('--fragment')));
      expect(args, isNot(contains('--ech')));
      expect(args, isNot(contains('--api-address')));
      expect(args, contains('--tls-ciphers'));
    });
  });

  group('the gateway scan', () {
    test('it scans past the gateway named by hand on ports of its own', () {
      final args = const TunnelSettings(endpoint: '162.159.198.1:443')
          .toScanArguments(
            bindAddress: '127.0.0.1:40001',
            httpProxyAddress: '127.0.0.1:40002',
          );
      expect(_value(args, '--bind'), '127.0.0.1:40001');
      expect(_value(args, '--http-proxy'), '127.0.0.1:40002');
      expect(_value(args, '--log-level'), 'info');
      expect(args, isNot(contains('--peer')));
      expect(args, contains('--masque'));
    });

    test('both hops are scanned for classic gool and masque in masque', () {
      final classic = const TunnelSettings(
        protocol: CoreProtocol.goolClassic,
        wiwOuter: '162.159.192.1:2408',
        wiwInner: '162.159.192.2:2408',
      ).toScanArguments(bindAddress: 'a', httpProxyAddress: 'b');
      expect(classic, contains('--wiw-scan'));
      expect(classic, isNot(contains('--wiw-outer')));

      final mim = const TunnelSettings(
        protocol: CoreProtocol.mim,
        endpoint: '162.159.198.1:443',
        mimInner: '162.159.198.2:443',
      ).toScanArguments(bindAddress: 'a', httpProxyAddress: 'b');
      expect(mim, isNot(contains('--mim-outer')));
      expect(mim, isNot(contains('--mim-inner')));
    });

    test('what is found goes where each protocol keeps it', () {
      const found = GatewayScan('162.159.198.2:443', '162.159.198.9:443');
      expect(_masque.withFoundGateway(found).endpoint, '162.159.198.2:443');
      final mim = const TunnelSettings(
        protocol: CoreProtocol.mim,
      ).withFoundGateway(found);
      expect(mim.endpoint, '162.159.198.2:443');
      expect(mim.mimInner, '162.159.198.9:443');
      final classic = const TunnelSettings(
        protocol: CoreProtocol.goolClassic,
      ).withFoundGateway(found);
      expect(classic.wiwOuter, '162.159.198.2:443');
      expect(classic.wiwInner, '162.159.198.9:443');
      expect(classic.endpoint, isEmpty);
    });

    test('scanning is offered only where the core dials warp itself', () {
      expect(_masque.canFindGateway, isTrue);
      expect(
        const TunnelSettings(core: CoreEngine.chain).canFindGateway,
        isTrue,
      );
      expect(
        const TunnelSettings(core: CoreEngine.psiphonReverse).canFindGateway,
        isFalse,
      );
      expect(
        const TunnelSettings(core: CoreEngine.psiphon).canFindGateway,
        isFalse,
      );
    });

    test('the lines the core names its gateway with are read', () {
      expect(
        CoreJobs.parseGateway(
          CoreProtocol.masque,
          '[2026-10-15T10:00:00Z INFO  aether] [+] selected MASQUE gateway '
          '162.159.198.2:443 (rtt 41ms)',
        ),
        const GatewayScan('162.159.198.2:443'),
      );
      expect(
        CoreJobs.parseGateway(
          CoreProtocol.wireguard,
          '[+] selected WireGuard endpoint 188.114.97.3:878 using aethernoize '
          "profile 'firewall'",
        ),
        const GatewayScan('188.114.97.3:878'),
      );
      expect(
        CoreJobs.parseGateway(
          CoreProtocol.goolClassic,
          '[+] using cloudflare edge 162.159.192.7:2408 (outer) and '
          '162.159.195.1:500 (inner)',
        ),
        const GatewayScan('162.159.192.7:2408', '162.159.195.1:500'),
      );
      expect(
        CoreJobs.parseGateway(
          CoreProtocol.mim,
          '[+] masque-in-masque ready: 162.159.198.1:443 (outer) and '
          '162.159.198.2:8443 (inner)',
        ),
        const GatewayScan('162.159.198.1:443', '162.159.198.2:8443'),
      );
      expect(
        CoreJobs.parseGateway(
          CoreProtocol.gool,
          '[+] gool ready: masque 162.159.198.1:443 carries wireguard '
          '162.159.192.1:2408',
        ),
        const GatewayScan('162.159.198.1:443'),
      );
      expect(
        CoreJobs.parseGateway(
          CoreProtocol.masque,
          '[+] selected WireGuard endpoint 188.114.97.3:878',
        ),
        isNull,
      );
    });

    test('an ipv6 gateway is written the way the core reads it back', () {
      expect(
        CoreJobs.endpointOf('2606:4700:103::1:443'),
        '[2606:4700:103::1]:443',
      );
      expect(
        CoreJobs.endpointOf('[2606:4700:103::1]:443'),
        '[2606:4700:103::1]:443',
      );
      expect(CoreJobs.endpointOf('162.159.198.1:443,'), '162.159.198.1:443');
      expect(CoreJobs.endpointOf('gateway'), isNull);
      expect(CoreJobs.endpointOf('162.159.198.1:99999'), isNull);
      expect(CoreJobs.endpointOf('example.com:443'), isNull);
    });

    test('with an exit rule only a gateway whose exit passed counts', () {
      final match = CoreJobs.gatewayMatcher(
        CoreProtocol.masque,
        exitRuled: true,
      );
      expect(match('[+] selected MASQUE gateway 162.159.198.1:443'), isNull);
      expect(match('[-] exit location IR rejected (not IR)'), isNull);
      expect(match('[+] exit location DE accepted (not IR)'), isNull);
      expect(match('[+] selected MASQUE gateway 162.159.198.2:443'), isNull);
      expect(
        match('[+] exit location DE accepted (not IR)'),
        const GatewayScan('162.159.198.2:443'),
      );

      final mim = CoreJobs.gatewayMatcher(CoreProtocol.mim, exitRuled: true);
      expect(
        mim(
          '[+] masque-in-masque ready: 162.159.198.1:443 (outer) and '
          '162.159.198.2:443 (inner)',
        ),
        const GatewayScan('162.159.198.1:443', '162.159.198.2:443'),
      );
    });

    test('the clock and module in front of a line are dropped', () {
      expect(
        CoreJobs.cleanLine('\x1B[2m2026\x1B[0m [-] tor: x\r'),
        '2026 [-] tor: x',
      );
    });
  });

  group(
    'jobs against a core that behaves like the real one',
    () {
      late Directory root;
      late Directory support;
      late File core;
      late CoreJobs jobs;

      Future<void> fakeCore(String body) async {
        core.writeAsStringSync('#!/bin/sh\n$body\n');
        await Process.run('chmod', <String>['+x', core.path]);
      }

      File key(String name) => File('${support.path}/core/$name');

      setUp(() {
        root = Directory.systemTemp.createTempSync('oblivion-jobs-');
        support = Directory('${root.path}/support')..createSync();
        core = File('${root.path}/aether');
        jobs = CoreJobs(
          TunnelChannel.instance,
          support: () async => support,
          binary: () async => core.path,
          layout: IdentityLayout.desktop,
        );
      });

      tearDown(() => root.deleteSync(recursive: true));

      test(
        'new keys take the place of the old ones once all are there',
        () async {
          Directory('${support.path}/core').createSync();
          key('aether-masque.toml').writeAsStringSync('device_id = "old"\n');
          key('aether.toml').writeAsStringSync('device_id = "wg"\n');
          await fakeCore(r'''
printf 'device_id = "new"\n' > "$AETHER_MASQUE_CONFIG"
printf 'device_id = "inner"\n' > "${AETHER_MASQUE_CONFIG%.toml}-secondary.toml"
echo "[2026-10-15T10:00:00Z INFO  aether] [+] identities ready: masque, masque inner"
''');
          final lines = <String>[];
          final result = await jobs.renewKeys(
            _masque,
            WarpKeyKind.mim,
            onLine: lines.add,
          );

          expect(result.succeeded, isTrue, reason: result.problem);
          expect(result.value, <String>[
            'aether-masque.toml',
            'aether-masque-secondary.toml',
          ]);
          expect(key('aether-masque.toml').readAsStringSync(), contains('new'));
          expect(
            key('aether-masque-secondary.toml').readAsStringSync(),
            contains('inner'),
          );
          expect(key('aether.toml').readAsStringSync(), contains('wg'));
          expect(
            Directory('${support.path}/core-renewal').existsSync(),
            isFalse,
          );
          expect(lines.last, contains('identities ready'));
        },
      );

      test('a refused registration leaves the keys in use alone', () async {
        Directory('${support.path}/core').createSync();
        key('aether-masque.toml').writeAsStringSync('device_id = "old"\n');
        await fakeCore(r'''
echo '[2026-10-15T10:00:00Z INFO  aether] [+] no masque identity found'
echo 'Error: Api("too many registrations")' >&2
exit 1
''');
        final result = await jobs.renewKeys(_masque, WarpKeyKind.masque);

        expect(result.succeeded, isFalse);
        expect(result.problem, contains('too many registrations'));
        expect(key('aether-masque.toml').readAsStringSync(), contains('old'));
        expect(Directory('${support.path}/core-renewal').existsSync(), isFalse);
      });

      test('keys that did not all come back are not used', () async {
        Directory('${support.path}/core').createSync();
        key('aether-masque.toml').writeAsStringSync('device_id = "old"\n');
        await fakeCore(r'''
printf 'device_id = "new"\n' > "$AETHER_MASQUE_CONFIG"
echo "[+] identities ready: masque"
''');
        final result = await jobs.renewKeys(_masque, WarpKeyKind.mim);

        expect(result.succeeded, isFalse);
        expect(result.problem, contains('aether-masque-secondary.toml'));
        expect(key('aether-masque.toml').readAsStringSync(), contains('old'));
      });

      test(
        'the scan ends at the gateway it names and stops the core',
        () async {
          await fakeCore(r'''
env > "$(dirname "$AETHER_CONFIG")/environment"
echo "args: $*" > "$(dirname "$AETHER_CONFIG")/arguments"
echo "[+] probing 40 candidates"
echo "[+] selected MASQUE gateway 162.159.198.2:443 (rtt 41ms)"
echo "[+] exit location DE accepted (not IR)"
sleep 30
''');
          final watch = Stopwatch()..start();
          final result = await jobs.findGateway(
            const TunnelSettings(endpoint: '162.159.198.1:443', exitLoc: '!IR'),
          );
          watch.stop();

          expect(result.value, const GatewayScan('162.159.198.2:443'));
          expect(watch.elapsed, lessThan(const Duration(seconds: 10)));

          final environment = File(
            '${support.path}/core/environment',
          ).readAsStringSync();
          expect(environment, contains('AETHER_EXIT_LOC=!IR'));
          expect(environment, contains('OBLIVION_CORE_OWNER=$pid'));
          expect(
            environment,
            contains('AETHER_CONFIG=${support.path}/core/aether.toml'),
          );
          final arguments = File(
            '${support.path}/core/arguments',
          ).readAsStringSync();
          expect(arguments, isNot(contains('162.159.198.1')));
        },
      );

      test('a scan that is called off stops the core at once', () async {
        await fakeCore('echo "[+] probing"\nsleep 30');
        final cancel = CoreJobCancel();
        final running = jobs.findGateway(_masque, cancel: cancel);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        cancel.cancel();
        final result = await running.timeout(const Duration(seconds: 10));
        expect(result.cancelled, isTrue);
      });

      test('a core that stops on its own says why', () async {
        await fakeCore('echo "[-] no gateway answered" >&2\nexit 3');
        final result = await jobs.findGateway(_masque);
        expect(result.succeeded, isFalse);
        expect(result.problem, contains('no gateway answered'));
      });

      test('without a core there is nothing to run', () async {
        final missing = CoreJobs(
          TunnelChannel.instance,
          support: () async => support,
          binary: () async => '${root.path}/nowhere',
        );
        final result = await missing.findGateway(_masque);
        expect(result.succeeded, isFalse);
        expect(result.problem, contains('missing'));
      });
    },
    skip: Platform.isLinux || Platform.isMacOS
        ? false
        : 'the fake core is a shell script',
  );
}
