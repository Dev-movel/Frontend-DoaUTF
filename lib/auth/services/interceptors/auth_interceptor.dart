import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../token_storage.dart';

class AuthInterceptor extends Interceptor {
  final GlobalKey<NavigatorState> navigatorKey;

  bool _isRefreshing = false;

  AuthInterceptor({required this.navigatorKey});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshEndpoint =
        err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/login');

    if (!isUnauthorized || isRefreshEndpoint || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;

    try {
      final refreshed = await AuthService.instance.refreshToken();

      if (refreshed) {
        final newToken = await TokenStorage.instance.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

        final dio = Dio();
        final retryResponse = await dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } else {
        await _forceLogout();
        handler.next(err);
      }
    } catch (_) {
      await _forceLogout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _forceLogout() async {
    await AuthService.instance.logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}