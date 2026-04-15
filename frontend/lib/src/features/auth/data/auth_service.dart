import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/strings.dart';
import '../../../core/utils/phone_normalize.dart';

String? _messageFromResponseData(dynamic body) {
  if (body is Map) {
    final m = body['message'];
    return m is String ? m : null;
  }
  if (body is String) {
    final t = body.trim();
    if (t.startsWith('{')) {
      try {
        final map = jsonDecode(t);
        if (map is Map && map['message'] is String) {
          return map['message'] as String;
        }
      } catch (_) {}
    }
    return t.isEmpty ? null : t;
  }
  return null;
}

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  /// GET /ping to verify the app can reach the backend (same client as register/login).
  Future<bool> checkConnectivity() async {
    try {
      final r = await apiClient.dio.get<Map<String, dynamic>>('/ping');
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
    String? telegramNick,
  }) async {
    const maxAttempts = 3;
    DioException? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final phoneApi = normalizeRuPhoneForApi(phone) ?? phone;
        final response = await apiClient.dio.post<Map<String, dynamic>>(
          '/register',
          data: <String, dynamic>{
            'phone': phoneApi,
            'password': password,
            'full_name': fullName,
            'telegram_nick': telegramNick ?? '',
          },
          options: Options(contentType: 'application/json'),
        );
        final data = response.data;
        if (data == null) throw Exception(AppStrings.emptyServerResponse);
        return data;
      } on DioException catch (e) {
        lastError = e;
        if (e.response != null) {
          final msg = _messageFromResponseData(e.response?.data);
          throw Exception(msg ?? AppStrings.registrationError);
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
      }
    }
    final msg = lastError?.message ??
        lastError?.type.toString() ??
        AppStrings.noConnectionFallback;
    throw Exception(
        AppStrings.noConnectionDetails(ApiClient.defaultBaseUrl, msg));
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    const maxAttempts = 3;
    DioException? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final phoneApi = normalizeRuPhoneForApi(phone) ?? phone;
        final response = await apiClient.dio.post<dynamic>(
          '/login',
          data: <String, dynamic>{'phone': phoneApi, 'password': password},
          options: Options(contentType: 'application/json'),
        );
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        if (raw is Map) return Map<String, dynamic>.from(raw);
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
        return <String, dynamic>{};
      } on DioException catch (e) {
        lastError = e;
        if (e.response != null) {
          final msg = _messageFromResponseData(e.response?.data);
          throw Exception(msg ?? AppStrings.loginError);
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
      }
    }
    final msg = lastError?.message ??
        lastError?.type.toString() ??
        AppStrings.noConnectionFallback;
    throw Exception(
        AppStrings.noConnectionDetails(ApiClient.defaultBaseUrl, msg));
  }
}
