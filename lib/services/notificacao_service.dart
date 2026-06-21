import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/api_client.dart';
import '../models/notificacao.dart';

class NotificacaoService {
  NotificacaoService._();
  static final NotificacaoService instance = NotificacaoService._();

  Dio get _dio => ApiClient.instance;

  Future<List<Notificacao>> listar({bool apenasNaoLidas = false}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/notificacoes',
        queryParameters: apenasNaoLidas ? {'apenas_nao_lidas': true} : null,
      );
      return (response.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(Notificacao.fromJson)
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /notificacoes] ${e.response?.statusCode}: ${e.response?.data}');
      return [];
    }
  }

  Future<int> contarNaoLidas() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notificacoes/nao-lidas/count',
      );
      return (response.data?['total'] as int?) ?? 0;
    } on DioException catch (e) {
      debugPrint('❌ [GET /notificacoes/nao-lidas/count] ${e.response?.statusCode}');
      return 0;
    }
  }

  Future<void> marcarTodasLidas() async {
    try {
      await _dio.patch<void>('/notificacoes/lidas');
    } on DioException catch (e) {
      debugPrint('❌ [PATCH /notificacoes/lidas] ${e.response?.statusCode}');
    }
  }

  Future<void> marcarLida(int id) async {
    try {
      await _dio.patch<void>('/notificacoes/$id/lida');
    } on DioException catch (e) {
      debugPrint('❌ [PATCH /notificacoes/$id/lida] ${e.response?.statusCode}');
    }
  }
}
