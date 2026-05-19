import 'package:dio/dio.dart';
import '../auth/services/api_client.dart';
import '../models/agendamento.dart';

class AgendamentoService {
  AgendamentoService._();
  static final AgendamentoService instance = AgendamentoService._();

  Dio get _dio => ApiClient.instance;

  Future<Agendamento?> getByItem(int itemId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/itens/$itemId/agendamento',
    );
    if (response.data == null) return null;
    return Agendamento.fromJson(response.data!);
  }

  Future<Agendamento> sugerirHorario(int itemId, DateTime data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/itens/$itemId/agendamento/sugerir',
      data: {
        'data_hora': data.toUtc().toIso8601String(),
      },
    );
    return Agendamento.fromJson(response.data!);
  }

  Future<Agendamento> confirmarAgendamento(int itemId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/itens/$itemId/agendamento/confirmar',
    );
    return Agendamento.fromJson(response.data!);
  }

  Future<Agendamento> concluirEntrega(int itemId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/itens/$itemId/agendamento/concluir',
    );
    final data = response.data ?? {};
    final agendamentoJson = data['agendamento'] ?? data;
    return Agendamento.fromJson(agendamentoJson as Map<String, dynamic>);
  }

  Future<Agendamento> proporDisponibilidade(
    int itemId,
    DateTime data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/itens/$itemId/agendamento/disponibilidade',
      data: {
        'data_hora': data.toUtc().toIso8601String(),
      },
    );
    return Agendamento.fromJson(response.data!);
  }
}
