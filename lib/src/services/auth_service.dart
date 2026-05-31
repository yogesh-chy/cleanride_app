import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  const AuthService(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/login/',
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data ?? {};
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;

      if (access == null || refresh == null) {
        throw const AuthException('Login response did not include tokens.');
      }

      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );

      return me();
    } on DioException catch (error) {
      throw AuthException(_messageFromDio(error));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      await _apiClient.dio.post(
        '/register/',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
    } on DioException catch (error) {
      throw AuthException(_messageFromDio(error));
    }
  }

  Future<AppUser> updateProfile({
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/me/',
        data: {
          'name': name.trim(),
          'phone': phone?.trim(),
        },
      );
      return AppUser.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw AuthException(_messageFromDio(error));
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/change-password/',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (error) {
      throw AuthException(_messageFromDio(error));
    }
  }

  Future<AppUser> me() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/me/');
      return AppUser.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw AuthException(_messageFromDio(error));
    }
  }

  Future<void> logout() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh != null) {
      try {
        await _apiClient.dio.post('/logout/', data: {'refresh': refresh});
      } on DioException {
        // Clearing local tokens is still the right outcome if the API is down.
      }
    }
    await _tokenStorage.clear();
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      // Handle field-specific validation errors from Django Rest Framework
      if (data.containsKey('email') && data['email'] is List) {
        return (data['email'] as List).join(', ');
      }
      if (data.containsKey('password') && data['password'] is List) {
        return (data['password'] as List).join(', ');
      }
      if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
        return (data['non_field_errors'] as List).join(', ');
      }
      final message = data['message'] ?? data['detail'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Could not reach the CleanRide API. Check that the backend is running.';
    }

    return 'Something went wrong. Please try again.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
