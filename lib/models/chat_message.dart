import 'dart:convert';

class ChatMessage {
  final int? id;
  final int remetenteId;
  final String conteudo;
  final DateTime criadoEm;
  final bool enviandoLocalmente;

  const ChatMessage({
    this.id,
    required this.remetenteId,
    required this.conteudo,
    required this.criadoEm,
    this.enviandoLocalmente = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      remetenteId:
          json['remetente_id'] as int? ?? json['remetenteId'] as int? ?? 0,
      conteudo: json['conteudo'] as String? ?? '',
      criadoEm: _parseData(json['criado_em'] ?? json['criadoEm']),
    );
  }

  static DateTime _parseData(dynamic raw) {
    if (raw == null) return DateTime.now();
    final s = raw.toString();
    final utcStr = (s.endsWith('Z') || s.contains('+')) ? s : '${s}Z';
    return DateTime.tryParse(utcStr)?.toLocal() ?? DateTime.now();
  }

  static ChatMessage? tryFromWebSocket(dynamic data) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      return ChatMessage.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
