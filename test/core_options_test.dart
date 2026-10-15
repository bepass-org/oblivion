import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

String? _valueAfter(List<String> args, String flag) {
  final at = args.indexOf(flag);
  if (at < 0 || at + 1 >= args.length) return null;
  return args[at + 1];
}

void main() {
  group('masque server name', () {
    test('the default name is sent by name, never left to chance', () {
      final args = const TunnelSettings().toCoreArguments();
      expect(_valueAfter(args, '--masque-sni'), 'www.cloudflare.com');
      expect(
        const TunnelSettings().masqueServerName,
        TunnelSettings.defaultMasqueSni,
      );
    });

    test('the same choice gives the same name on every run', () {
      const settings = TunnelSettings(masqueSni: TunnelSettings.warpMasqueSni);
      final first = settings.toCoreArguments();
      for (var run = 0; run < 20; run++) {
        expect(settings.toCoreArguments(), first);
      }
      expect(
        _valueAfter(first, '--masque-sni'),
        'consumer-masque.cloudflareclient.com',
      );
    });

    test('a name of its own is told apart from the two presets', () {
      expect(const TunnelSettings().masqueSniCustom, isFalse);
      expect(
        const TunnelSettings(masqueSni: 'www.cloudflare.com').masqueSniCustom,
        isFalse,
      );
      expect(
        const TunnelSettings(
          masqueSni: TunnelSettings.warpMasqueSni,
        ).masqueSniCustom,
        isFalse,
      );
      expect(
        const TunnelSettings(masqueSni: 'front.example.test').masqueSniCustom,
        isTrue,
      );
    });

    test('a name reaches every masque handshake, trimmed', () {
      for (final protocol in <CoreProtocol>[
        CoreProtocol.masque,
        CoreProtocol.mim,
        CoreProtocol.gool,
      ]) {
        final args = TunnelSettings(
          protocol: protocol,
          masqueSni: '  consumer-masque.cloudflareclient.com ',
        ).toCoreArguments();
        expect(
          _valueAfter(args, '--masque-sni'),
          'consumer-masque.cloudflareclient.com',
          reason: protocol.wire,
        );
      }
    });

    test('wireguard has no masque handshake to name', () {
      for (final protocol in <CoreProtocol>[
        CoreProtocol.wireguard,
        CoreProtocol.goolClassic,
      ]) {
        final args = TunnelSettings(
          protocol: protocol,
          masqueSni: 'www.cloudflare.com',
        ).toCoreArguments();
        expect(args, isNot(contains('--masque-sni')), reason: protocol.wire);
      }
    });

    test('a domain name is taken and anything else is refused', () {
      for (final name in <String>[
        'www.cloudflare.com',
        'consumer-masque.cloudflareclient.com',
        ' front.example.test ',
        'front.example.test.',
        'localhost',
      ]) {
        expect(TunnelSettings.isServerName(name), isTrue, reason: name);
      }
      for (final name in <String>[
        '',
        '1.1.1.1',
        '1.1.1.1.',
        '2606:4700:4700::1111',
        '[2606:4700:4700::1111]',
        'www..cloudflare.com',
        'www.cloudflare.com..',
        '.',
        'www cloudflare com',
        'www.cloudflare.com:443',
        'https://www.cloudflare.com',
      ]) {
        expect(TunnelSettings.isServerName(name), isFalse, reason: name);
      }
    });
  });

  group('encrypted client hello', () {
    test('off by default, with nothing sent', () {
      final args = const TunnelSettings().toCoreArguments();
      expect(args, isNot(contains('--ech')));
      expect(args, isNot(contains('--ech-dns')));
      expect(args, isNot(contains('--ech-domain')));
    });

    test('it covers the warp api calls, so every protocol asks for it', () {
      for (final protocol in CoreProtocol.values) {
        final args = TunnelSettings(
          protocol: protocol,
          echMode: EchMode.auto,
        ).toCoreArguments();
        expect(_valueAfter(args, '--ech'), 'auto', reason: protocol.wire);
      }
    });

    test('the resolver and the domain travel only with ech on', () {
      const named = TunnelSettings(
        echDns: ' https://doq.dns4all.eu/dns-query@address=2.2.2.2 ',
        echDomain: ' crypto.cloudflare.com ',
      );
      expect(named.toCoreArguments(), isNot(contains('--ech-dns')));
      expect(named.toCoreArguments(), isNot(contains('--ech-domain')));

      final args = named.copyWith(echMode: EchMode.auto).toCoreArguments();
      expect(
        _valueAfter(args, '--ech-dns'),
        'https://doq.dns4all.eu/dns-query@address=2.2.2.2',
      );
      expect(_valueAfter(args, '--ech-domain'), 'crypto.cloudflare.com');
    });

    test('a resolver is read the way the core reads it', () {
      for (final resolver in <String>[
        'udp://1.1.1.1',
        ' UDP://8.8.8.8:5353 ',
        'tcp://1.1.1.1',
        'tcp://[2606:4700:4700::1111]',
        'udp://[::1]:5353/',
        'https://doq.dns4all.eu/dns-query',
        'https://1.1.1.1:8443/dns-query',
        'https://doq.dns4all.eu/dns-query@address=2.2.2.2@sni=google.com',
        ' https://doq.dns4all.eu/dns-query@SNI=google.com@Address=2.2.2.2 ',
        'https://doq.dns4all.eu/dns-query@address=[2606:4700::1111]',
        'https://doq.dns4all.eu/dns-query@address=2606:4700::1111',
        'https://doq.dns4all.eu/dns-query@address=front.example.net',
        'https://doq.dns4all.eu/dns-query@sni=google.com',
        'https://doq.dns4all.eu@address=2.2.2.2',
      ]) {
        expect(
          TunnelSettings.isEchResolver(resolver),
          isTrue,
          reason: resolver,
        );
      }
    });

    test('a resolver the core would stop on is refused', () {
      for (final resolver in <String>[
        '1.1.1.1',
        'dns.google',
        'tls://1.1.1.1',
        'udp://dns.google',
        'tcp://',
        'udp://1.1.1.1:99999',
        'https://',
        'https:///dns-query',
        '',
        'https://doq.dns4all.eu/dns-query@address=',
        'https://doq.dns4all.eu/dns-query@address=2.2.2.2:443',
        'https://doq.dns4all.eu/dns-query@address=not a name',
        'https://doq.dns4all.eu/dns-query@sni=',
        'https://doq.dns4all.eu/dns-query@sni=2.2.2.2',
        'https://doq.dns4all.eu/dns-query@sni=[::1]',
        'https://doq.dns4all.eu/dns-query@sni=google.com@sni=bing.com',
        'https://doq.dns4all.eu/dns-query@address=1.1.1.1@address=2.2.2.2',
        'https://doq.dns4all.eu/dns-query@port=443',
        'https://doq.dns4all.eu/dns-query@google.com',
        'https://user@doq.dns4all.eu/dns-query',
        'https://@address=2.2.2.2',
      ]) {
        expect(
          TunnelSettings.isEchResolver(resolver),
          isFalse,
          reason: resolver,
        );
      }
    });

    test('the key domain is a dns name', () {
      final long = '${'a' * 64}.com';
      for (final name in <String>[
        'cloudflare-ech.com',
        'crypto.cloudflare.com',
        'ip.gs',
        'ip.gs.',
        '_ech.example',
      ]) {
        expect(TunnelSettings.isDomainName(name), isTrue, reason: name);
      }
      for (final name in <String>[
        '',
        '.',
        'a..b',
        'with space.com',
        'https://ip.gs',
        'ip.gs/',
        long,
      ]) {
        expect(TunnelSettings.isDomainName(name), isFalse, reason: name);
      }
    });
  });

  group('fragmenting', () {
    test('the default chunks match the core default', () {
      expect(const TunnelSettings().fragmentSize, '8-16');
      expect(const TunnelSettings().fragmentDelay, '2-10');
    });

    test('nothing is split unless asked for', () {
      expect(
        const TunnelSettings().toCoreArguments(),
        isNot(contains('--fragment')),
      );
    });

    test('the warp api calls are split whatever the protocol', () {
      for (final protocol in CoreProtocol.values) {
        final args = TunnelSettings(
          protocol: protocol,
          fragment: true,
          fragmentSize: '8-16',
          fragmentDelay: '2-10',
        ).toCoreArguments();
        expect(args, contains('--fragment'), reason: protocol.wire);
        expect(_valueAfter(args, '--fragment-size'), '8-16');
        expect(_valueAfter(args, '--fragment-delay'), '2-10');
      }
    });
  });

  group('tls fingerprint', () {
    test('chrome as the core ships it, unless told otherwise', () {
      final args = const TunnelSettings().toCoreArguments();
      expect(args, isNot(contains('--tls-ciphers')));
      expect(args, isNot(contains('--tls-groups')));
      expect(args, isNot(contains('--disable-grease')));
    });

    test('the cipher list, the groups and grease reach the core', () {
      final args = const TunnelSettings(
        protocol: CoreProtocol.wireguard,
        tlsCiphers:
            ' ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256 ',
        tlsGroups: 'X25519:P-256',
        grease: false,
      ).toCoreArguments();

      expect(
        _valueAfter(args, '--tls-ciphers'),
        'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256',
      );
      expect(_valueAfter(args, '--tls-groups'), 'X25519:P-256');
      expect(args, contains('--disable-grease'));
    });

    test('a cipher list is names and the separators boringssl reads', () {
      for (final list in <String>[
        'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256',
        'ALL:!aPSK:!ECDSA+SHA1:!3DES',
        ' ECDHE-RSA-CHACHA20-POLY1305 ',
      ]) {
        expect(TunnelSettings.isCipherList(list), isTrue, reason: list);
      }
      for (final list in <String>['', '   ', ':::', 'AES128;rm -rf', 'é']) {
        expect(TunnelSettings.isCipherList(list), isFalse, reason: list);
      }
    });
  });

  group('warp api address', () {
    test('the api is reached by its own name until another is given', () {
      expect(
        const TunnelSettings().toCoreArguments(),
        isNot(contains('--api-address')),
      );
      final args = const TunnelSettings(
        apiAddress: ' 188.114.97.6:2053 ',
      ).toCoreArguments();
      expect(_valueAfter(args, '--api-address'), '188.114.97.6:2053');
    });

    test('an address is read the way the core reads it', () {
      for (final address in <String>[
        '188.114.97.6',
        '188.114.97.6:2053',
        'edge.example.com',
        'edge.example.com:443',
        '2606:4700::1',
        '[2606:4700::1]',
        '[2606:4700::1]:8443',
        ' 141.101.113.10 ',
      ]) {
        expect(TunnelSettings.isApiAddress(address), isTrue, reason: address);
      }
      for (final address in <String>[
        '',
        '188.114.97.6:0',
        '188.114.97.6:65536',
        '188.114.97.6:',
        'edge.example.com:https',
        ':443',
        '1.2.3.4:443:5',
        '[2606:4700::1:443',
        '2606:4700:4700:0:0:0:0:1111:443',
        'https://edge.example.com',
        'edge example.com',
      ]) {
        expect(TunnelSettings.isApiAddress(address), isFalse, reason: address);
      }
    });
  });

  group('cores that run no aether', () {
    test('psiphon and tor alone get no aether flags at all', () {
      for (final core in <CoreEngine>[CoreEngine.psiphon, CoreEngine.tor]) {
        final args = TunnelSettings(
          core: core,
          protocol: CoreProtocol.gool,
          masqueSni: 'www.cloudflare.com',
          echMode: EchMode.auto,
          fragment: true,
          tlsCiphers: 'ALL',
          grease: false,
          apiAddress: '188.114.97.6',
        ).toCoreArguments();
        expect(args, isEmpty, reason: core.wire);
      }
    });
  });

  group('psiphon cdn lists', () {
    test('the picked lists travel in the order psiphon names them', () {
      const settings = TunnelSettings(
        core: CoreEngine.psiphon,
        psiphonCdnSets: <String>{'fastly', 'cloudflare', 'github'},
      );
      expect(settings.psiphonCdnSetList, <String>[
        'cloudflare',
        'fastly',
        'github',
      ]);
      expect(
        settings.toPlatformPayload()['psiphonCdnSets'],
        'cloudflare,fastly,github',
      );
    });

    test('a name psiphon does not know is never sent', () {
      const settings = TunnelSettings(
        psiphonCdnSets: <String>{'cloudflare', 'nowhere'},
      );
      expect(settings.toPlatformPayload()['psiphonCdnSets'], 'cloudflare');
    });

    test('none picked leaves the choice to psiphon', () {
      expect(const TunnelSettings().toPlatformPayload()['psiphonCdnSets'], '');
    });
  });
}
