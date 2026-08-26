import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/geo_endpoint.dart';

enum GeoFormat { json, trace }

class GeoProvider {
  const GeoProvider(this.uri, this.format);

  final Uri uri;
  final GeoFormat format;
}

class GeoService {
  GeoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final GeoProvider _trace = GeoProvider(
    Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'),
    GeoFormat.trace,
  );

  static final List<GeoProvider> _providers = <GeoProvider>[
    _trace,
    GeoProvider(Uri.parse('https://ipwho.is/'), GeoFormat.json),
    GeoProvider(Uri.parse('https://ipinfo.io/json'), GeoFormat.json),
    GeoProvider(Uri.parse('https://ipapi.co/json/'), GeoFormat.json),
    GeoProvider(
      Uri.parse(
        'http://ip-api.com/json/?fields=status,country,countryCode,city,isp,query',
      ),
      GeoFormat.json,
    ),
  ];

  static final List<GeoProvider> _ispProviders = <GeoProvider>[
    GeoProvider(Uri.parse('https://ipwho.is/'), GeoFormat.json),
    GeoProvider(
      Uri.parse(
        'http://ip-api.com/json/?fields=status,country,countryCode,city,isp,query',
      ),
      GeoFormat.json,
    ),
    GeoProvider(Uri.parse('https://ipinfo.io/json'), GeoFormat.json),
  ];

  static const Duration _timeout = Duration(seconds: 8);
  static const int _roundsThroughProxy = 4;
  static const Duration _retryDelay = Duration(milliseconds: 900);

  Future<GeoEndpoint?> lookupDirect() async {
    for (final provider in _providers) {
      final host = provider.uri.host;
      try {
        final response = await _client
            .get(
              provider.uri,
              headers: const <String, String>{
                'accept': 'application/json, text/plain, */*',
                'user-agent': 'Oblivion/1.0',
              },
            )
            .timeout(_timeout);
        if (response.statusCode < 200 || response.statusCode > 299) {
          _report('origin lookup: $host returned ${response.statusCode}');
          continue;
        }
        final endpoint = await _decode(response.body, provider.format);
        if (endpoint != null) return endpoint;
        _report(
          'origin lookup: $host answered but the reply could not be read '
          '(${_preview(response.body)})',
        );
      } catch (error) {
        _report('origin lookup: $host failed: $error');
      }
    }

    _report('origin lookup: every provider failed');
    return null;
  }

  Future<GeoEndpoint?> lookupThroughProxy(int httpProxyPort) async {
    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..idleTimeout = _timeout
      ..userAgent = 'Oblivion/1.0'
      ..findProxy = (_) => 'PROXY 127.0.0.1:$httpProxyPort';

    try {
      for (var round = 0; round < _roundsThroughProxy; round++) {
        for (final provider in _providers) {
          final host = provider.uri.host;
          try {
            final body = await _getThrough(client, provider.uri);
            final endpoint = await _decode(body, provider.format);
            if (endpoint != null) {
              if (provider.format == GeoFormat.trace) {
                return endpoint.mergeIsp(await _lookupIsp(client));
              }
              return endpoint;
            }
            _report(
              'exit lookup: $host answered but the reply could not be read '
              '(${_preview(body)})',
            );
          } catch (error) {
            _report(
              'exit lookup: $host failed through the core proxy on '
              '127.0.0.1:$httpProxyPort: $error',
            );
          }
        }
        await Future<void>.delayed(_retryDelay);
      }
    } finally {
      client.close(force: true);
    }

    _report(
      'exit lookup: every provider failed on all $_roundsThroughProxy rounds',
    );
    return null;
  }

  Future<GeoEndpoint?> _lookupIsp(HttpClient client) async {
    for (final provider in _ispProviders) {
      try {
        final body = await _getThrough(client, provider.uri);
        final endpoint = _parseJson(body);
        if (endpoint != null && (endpoint.isp?.isNotEmpty ?? false)) {
          return endpoint;
        }
      } catch (error) {
        _report('isp lookup: ${provider.uri.host} failed: $error');
      }
    }
    return null;
  }

  Future<String> _getThrough(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri).timeout(_timeout);
    request.headers.set('accept', 'application/json, text/plain, */*');
    request.followRedirects = true;

    final response = await request.close().timeout(_timeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw HttpException('status ${response.statusCode}', uri: uri);
    }
    return body;
  }

  static void _report(String message) => debugPrint('[geo] $message');

  static String _preview(String body) {
    final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.isEmpty) return 'empty body';
    return flat.length <= 120 ? flat : '${flat.substring(0, 120)}...';
  }

  Future<GeoEndpoint?> _decode(String body, GeoFormat format) async {
    return switch (format) {
      GeoFormat.json => _parseJson(body),
      GeoFormat.trace => parseTrace(body),
    };
  }

  GeoEndpoint? _parseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['status'] == 'fail') return null;
      if (decoded['success'] == false) return null;
      if (decoded['error'] != null) return null;

      return GeoEndpoint.fromLookup(decoded);
    } catch (_) {
      return null;
    }
  }

  static GeoEndpoint? parseTrace(String body) {
    final fields = <String, String>{};
    for (final line in body.split('\n')) {
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      fields[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }

    final ip = fields['ip'];
    if (ip == null || ip.isEmpty) return null;

    return GeoEndpoint(
      ip: ip,
      countryCode: (fields['loc'] ?? '').toUpperCase(),
      colo: fields['colo'],
      warp: WarpStatus.fromWire(fields['warp']),
    );
  }

  void dispose() => _client.close();
}
