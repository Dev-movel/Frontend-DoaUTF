import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/token_storage.dart';

class SolicitacaoException implements Exception {
  final String message;
  const SolicitacaoException(this.message);
}

class SolicitacaoService {
  SolicitacaoService._();
  static final SolicitacaoService instance = SolicitacaoService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<int> criarSolicitacao(int itemId) async {
    try {
      final token = await TokenStorage.instance.getAccessToken();
      final response = await _dio.post(
        '/solicitacoes',
        data: {'item_id': itemId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['id'] as int;
    } on DioException catch (e) {
      debugPrint('❌ [POST /solicitacoes] ${e.response?.statusCode} – ${e.response?.data}');
      throw SolicitacaoException(switch (e.response?.statusCode) {
        400 => 'Item indisponível para solicitação.',
        403 => 'Você não pode solicitar seu próprio item.',
        404 => 'Item não encontrado.',
        409 => 'Você já fez uma solicitação para este item.',
        _   => 'Erro ao enviar solicitação. Tente novamente.',
      });
    }
  }

  /// Retorna mapa de item_id → solicitacao_id para o usuário logado.
  Future<Map<int, int>> buscarMinhasSolicitacoes() async {
    try {
      final token = await TokenStorage.instance.getAccessToken();
      final response = await _dio.get(
        '/solicitacoes/minhas',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final list = response.data as List<dynamic>;
      return {
        for (final s in list)
          if (s['item']?['id'] != null && s['id'] != null)
            s['item']['id'] as int: s['id'] as int,
      };
    } on DioException catch (e) {
      debugPrint('❌ [GET /solicitacoes/minhas] ${e.response?.statusCode}');
      return {};
    }
  }

  Future<void> cancelarSolicitacao(int solicitacaoId) async {
    try {
      final token = await TokenStorage.instance.getAccessToken();
      await _dio.delete(
        '/solicitacoes/$solicitacaoId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      debugPrint('❌ [DELETE /solicitacoes/$solicitacaoId] ${e.response?.statusCode} – ${e.response?.data}');
      throw SolicitacaoException(switch (e.response?.statusCode) {
        403 => 'Sem permissão para cancelar esta solicitação.',
        404 => 'Solicitação não encontrada.',
        _   => 'Erro ao cancelar solicitação. Tente novamente.',
      });
    }
  }
}
