import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_storage.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken:  json['accessToken']  as String,
        refreshToken: json['refreshToken'] as String,
      );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
 
    final tokens = AuthTokens.fromJson(response.data!);
    await TokenStorage.instance.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<bool> register({
    required String nome,
    required String email,
    required String senha,
    required String dataNascimento,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'nome': nome,
          'email': email,
          'senha': senha,
          'data_nascimento': dataNascimento,
        },
      );

      final data = response.data ?? {};

      if (data['requireVerification'] == true) return true;

      if (data.containsKey('access_token')) {
        final tokens = AuthTokens.fromJson(data);
        await TokenStorage.instance.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
      }

      return false;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final serverError = e.response?.data['erro'];
        if (serverError != null) {
          throw Exception(serverError); 
        }
      }
      throw Exception('Não foi possível conectar ao servidor. Tente novamente.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado.');
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String codigo,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-email',
      data: {'email': email, 'codigo': codigo},
    );

    final data = response.data ?? {};
    if (data.containsKey('access_token')) {
      final tokens = AuthTokens.fromJson(data);
      await TokenStorage.instance.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    await _dio.post<void>(
      '/auth/resend-verification',
      data: {'email': email},
    );

    final data = response.data ?? {};

    if (data['requireVerification'] == true) return true;

    if (data.containsKey('access_token')) {
      final tokens = AuthTokens.fromJson(data);
      await TokenStorage.instance.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
 
    return false;
  }

  Future<void> verifyEmail({
    required String email,
    required String codigo,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-email',
      data: {'email': email, 'codigo': codigo},
    );
 
    final data = response.data ?? {};
    if (data.containsKey('access_token')) {
      final tokens = AuthTokens.fromJson(data);
      await TokenStorage.instance.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
  }

  Future<void> resendVerificationCode({required String email}) async {
    await _dio.post<void>(
      '/auth/resend-verification',
      data: {'email': email},
    );
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await TokenStorage.instance.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final tokens = AuthTokens.fromJson(response.data!);
      await TokenStorage.instance.saveTokens(
        accessToken:  tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearTokens();
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      debugPrint('Chamando endpoint /auth/forgot-password com: $email');
      await _dio.post<void>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      debugPrint('E-mail de recuperação enviado!');
    } catch (e) {
      debugPrint('Erro ao enviar recuperação: $e');
      rethrow;
    }
  }
}