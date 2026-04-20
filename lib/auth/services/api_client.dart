import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import './interceptors/auth_interceptor.dart';

class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get instance {
    assert(
      _instance != null,
      'ApiClient não foi inicializado. Chame ApiClient.init() no main.dart.',
    );
    return _instance!;
  }

  static void init({
    required GlobalKey<NavigatorState> navigatorKey,
    String baseUrl = 'http://localhost:3000',
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(
      AuthInterceptor(navigatorKey: navigatorKey),
    );
    
    _instance = dio;
  }
}