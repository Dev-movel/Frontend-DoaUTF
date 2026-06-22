import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../auth/services/token_storage.dart';
import '../config/app_config.dart';
import '../models/chat_message.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  WebSocketChannel? _channel;

  /// Busca o histórico de mensagens via REST.
  Future<List<ChatMessage>> buscarHistorico(int solicitacaoId) async {
    try {
      final token = await TokenStorage.instance.getAccessToken();
      final response = await _dio.get(
        '/chat/$solicitacaoId/mensagens',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint(
          '❌ [GET /chat/$solicitacaoId/mensagens] ${e.response?.statusCode}');
      return [];
    }
  }

  /// Abre a conexão WebSocket para o chat dessa solicitação.
  Future<WebSocketChannel?> conectar(int solicitacaoId) async {
    try {
      final token = await TokenStorage.instance.getAccessToken();
      final wsBase = AppConfig.apiBaseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsBase/chat/$solicitacaoId?token=$token');
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      return channel;
    } catch (e) {
      debugPrint('❌ [WS /chat/$solicitacaoId] Falha ao conectar: $e');
      return null;
    }
  }

  /// Envia uma mensagem pelo WebSocket aberto.
  void enviar(String conteudo) {
    _channel?.sink.add(jsonEncode({'conteudo': conteudo}));
  }

  /// Fecha a conexão WebSocket.
  void fechar() {
    _channel?.sink.close();
    _channel = null;
  }
}