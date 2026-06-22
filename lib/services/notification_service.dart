import 'package:flutter/foundation.dart';

class ChatNotificacao {
  final int solicitacaoId;
  final String nomeOutroUsuario;
  final String tituloItem;
  String ultimaMensagem;
  int qtdNaoLidas;

  ChatNotificacao({
    required this.solicitacaoId,
    required this.nomeOutroUsuario,
    required this.tituloItem,
    required this.ultimaMensagem,
    this.qtdNaoLidas = 1,
  });
}

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<ChatNotificacao> _lista = [];

  List<ChatNotificacao> get lista => List.unmodifiable(_lista);

  int get totalNaoLidas => _lista.fold(0, (s, n) => s + n.qtdNaoLidas);

  void adicionarMensagem({
    required int solicitacaoId,
    required String nomeOutroUsuario,
    required String tituloItem,
    required String mensagem,
  }) {
    final idx = _lista.indexWhere((n) => n.solicitacaoId == solicitacaoId);
    if (idx >= 0) {
      _lista[idx].ultimaMensagem = mensagem;
      _lista[idx].qtdNaoLidas++;
    } else {
      _lista.add(ChatNotificacao(
        solicitacaoId: solicitacaoId,
        nomeOutroUsuario: nomeOutroUsuario,
        tituloItem: tituloItem,
        ultimaMensagem: mensagem,
      ));
    }
    notifyListeners();
  }

  void marcarComoLido(int solicitacaoId) {
    final antes = _lista.length;
    _lista.removeWhere((n) => n.solicitacaoId == solicitacaoId);
    if (_lista.length != antes) notifyListeners();
  }
}
