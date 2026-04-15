import 'package:dio/dio.dart';

import 'api_base_url_stub.dart' if (dart.library.io) 'api_base_url_io.dart'
    as api_base_url;

/// База API: см. [api_base_url.getApiBaseUrl]; переопределение - `--dart-define=API_HOST` / `API_PORT`.
const _apiHost = String.fromEnvironment('API_HOST', defaultValue: '');
const _apiPort = String.fromEnvironment('API_PORT', defaultValue: '');

const _chatHost = String.fromEnvironment('CHAT_HOST', defaultValue: '');
const _chatPort = String.fromEnvironment('CHAT_PORT', defaultValue: '');

class ApiClient {
  final Dio dio;

  ApiClient({String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? _defaultBaseUrl(),
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': 'MasterclassesApp/1.0',
          },
        ));

  static String _resolvedBaseUrl() {
    if (_apiHost.isNotEmpty) {
      final p = _apiPort.isEmpty ? '80' : _apiPort;
      return p == '80' ? 'http://$_apiHost' : 'http://$_apiHost:$p';
    }
    return api_base_url.getApiBaseUrl();
  }

  static String _defaultBaseUrl() => _resolvedBaseUrl();

  static String get defaultBaseUrl => _resolvedBaseUrl();

  static String resolveImageUrl(String url) {
    if (url.startsWith('http')) return url;
    final base = defaultBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  static String get chatBaseUrl {
    final api = Uri.parse(_resolvedBaseUrl());
    final host = _chatHost.isNotEmpty ? _chatHost : api.host;
    final portStr = _chatPort.isNotEmpty
        ? _chatPort
        : '${api_base_url.getDefaultChatPort()}';
    final port = int.tryParse(portStr) ?? api_base_url.getDefaultChatPort();
    return 'http://$host:$port';
  }
}
