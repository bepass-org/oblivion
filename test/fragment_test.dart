import 'package:flutter_test/flutter_test.dart';
import 'package:oblivion/data/models/tunnel_settings.dart';

TunnelSettings _h2({bool fragment = true}) {
  return TunnelSettings(
    protocol: CoreProtocol.masque,
    transport: MasqueTransport.http2,
    fragment: fragment,
  );
}

String? _valueAfter(List<String> args, String flag) {
  final at = args.indexOf(flag);
  if (at < 0 || at + 1 >= args.length) return null;
  return args[at + 1];
}

void main() {
  group('http/2 fragment defaults', () {
    test('fragment starts on because the core needs it on a filtered path', () {
      expect(const TunnelSettings().fragment, isTrue);
    });

    test('the chunk size matches the upstream default of 8 to 16', () {
      expect(const TunnelSettings().fragmentSize, '8-16');
      expect(const TunnelSettings().fragmentDelay, '2-10');
    });

    test('an h2 run carries the fragment switch and its ranges', () {
      final args = _h2().toCoreArguments();

      expect(args, contains('--h2'));
      expect(args, contains('--fragment'));
      expect(_valueAfter(args, '--fragment-size'), '8-16');
      expect(_valueAfter(args, '--fragment-delay'), '2-10');
    });

    test('turning the fragment off still runs h2 without the flag', () {
      final args = _h2(fragment: false).toCoreArguments();

      expect(args, contains('--h2'));
      expect(args, isNot(contains('--fragment')));
    });

    test('an h3 run carries no fragment switch at all', () {
      final args = const TunnelSettings().toCoreArguments();

      expect(args, contains('--masque'));
      expect(args, isNot(contains('--fragment')));
    });
  });

  group('gool stays the classic wireguard in wireguard on aether 2.3', () {
    test('unpinned hops keep asking the core to scan both wireguard hops', () {
      final args = const TunnelSettings(
        protocol: CoreProtocol.gool,
      ).toCoreArguments();

      expect(args, contains('--gool'));
      expect(args, contains('--wiw-scan'));
      expect(args, isNot(contains('--gool-classic')));
    });

    test('pinned hops travel as the wiw peers the classic mode reads', () {
      final args = const TunnelSettings(
        protocol: CoreProtocol.gool,
        wiwOuter: '162.159.192.1:2408',
        wiwInner: '188.114.96.1:894',
      ).toCoreArguments();

      expect(_valueAfter(args, '--wiw-outer'), '162.159.192.1:2408');
      expect(_valueAfter(args, '--wiw-inner'), '188.114.96.1:894');
      expect(args, isNot(contains('--wiw-scan')));
    });
  });
}
