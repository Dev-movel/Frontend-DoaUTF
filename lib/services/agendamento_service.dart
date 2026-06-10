import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/api_client.dart';
import '../models/agendamento.dart';

class AgendamentoException implements Exception {
  final String message;
  const AgendamentoException(this.message);
  
  @override
  String toString() => message;
}

class AgendamentoService {
  AgendamentoService._();
  static final AgendamentoService instance = AgendamentoService._();

  Dio get _dio => ApiClient.instance;

  Future<Agendamento?> getByItem(int itemId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/itens/$itemId/agendamento',
      );
      if (response.data == null) return null;
      return Agendamento.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; 
      debugPrint('❌ [GET /itens/$itemId/agendamento] Erro: ${e.response?.data}');
      throw const AgendamentoException('Erro ao buscar informações do agendamento.');
    }
  }

  Future<Agendamento> sugerirHorario(int itemId, DateTime data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/itens/$itemId/agendamento/sugerir',
        data: {'data_hora': data.toUtc().toIso8601String()},
      );
      final dataRes = response.data ?? {};
      final agendamentoJson = dataRes['agendamento'] ?? dataRes;
      return Agendamento.fromJson(agendamentoJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao sugerir horário.');
    }
  }

  Future<Agendamento> confirmarAgendamento(int itemId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/itens/$itemId/agendamento/confirmar',
      );
      final dataRes = response.data ?? {};
      final agendamentoJson = dataRes['agendamento'] ?? dataRes;
      return Agendamento.fromJson(agendamentoJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao confirmar agendamento.');
    }
  }

  Future<Agendamento> concluirEntrega(int itemId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/itens/$itemId/agendamento/concluir',
      );
      final dataRes = response.data ?? {};
      final agendamentoJson = dataRes['agendamento'] ?? dataRes;
      return Agendamento.fromJson(agendamentoJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao concluir entrega física.');
    }
  }

  Future<Agendamento> proporDisponibilidade(int itemId, DateTime data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/itens/$itemId/agendamento/disponibilidade',
        data: {'data_hora': data.toUtc().toIso8601String()},
      );
      final dataRes = response.data ?? {};
      final agendamentoJson = dataRes['agendamento'] ?? dataRes;
      return Agendamento.fromJson(agendamentoJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Erro ao propor disponibilidade.');
    }
  }

  AgendamentoException _handleError(DioException e, String defaultMessage) {
    debugPrint('[AGENDAMENTO SERVICE] ${e.response?.statusCode} – ${e.response?.data}');
    
    final erroBackend = e.response?.data is Map ? e.response?.data['erro'] : null;
    if (erroBackend != null) return AgendamentoException(erroBackend);

    return AgendamentoException(switch (e.response?.statusCode) {
      401 => 'Sessão expirada. Faça login novamente.',
      403 => 'Você não tem permissão para realizar esta ação neste item.',
      404 => 'Agendamento correspondente não encontrado.',
      422 => 'A data informada é inválida ou está no passado.',
      _   => defaultMessage,
    });
  }
}
