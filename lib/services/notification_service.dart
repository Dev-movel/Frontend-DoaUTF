import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/token_storage.dart';
import '../config/app_config.dart';

class AppNotificacao {
  final int id;
  final int solicitacaoId;
  final int meuId;
  final String usuarioNome;
  final String itemTitulo;
  final String mensagem;
  final bool lida;
  final DateTime criadoEm;

  const AppNotificacao({
    required this.id,
    required this.solicitacaoId,
    required this.meuId,
    required this.usuarioNome,
    required this.itemTitulo,
    required this.mensagem,
    this.lida = false,
    required this.criadoEm,
  });

  AppNotificacao copyWith({bool? lida}) => AppNotificacao(
        id: id,
        solicitacaoId: solicitacaoId,
        meuId: meuId,
        usuarioNome: usuarioNome,
        itemTitulo: itemTitulo,
        mensagem: mensagem,
        lida: lida ?? this.lida,
        criadoEm: criadoEm,
      );
}

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final List<AppNotificacao> _lista = [];
  int _nextId = 1;
  Timer? _pollingTimer;

  // Conversas que o usuário está visualizando agora — não geram notificação
  final Set<int> _chatsAbertos = {};

  List<AppNotificacao> get lista {
    final naoLidas = _lista.where((n) => !n.lida).toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return List.unmodifiable(naoLidas);
  }

  int get totalNaoLidas => _lista.where((n) => !n.lida).length;

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.instance.getAccessToken();
    return {'Authorization': 'Bearer $token'};
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void iniciarPolling({Duration intervalo = const Duration(seconds: 20)}) {
    _pollingTimer?.cancel();
    _buscarNaoLidas();
    _pollingTimer = Timer.periodic(intervalo, (_) => _buscarNaoLidas());
  }

  void pararPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Consulta GET /chat/conversas e atualiza o badge com base em nao_lidas > 0.
  Future<void> _buscarNaoLidas() async {
    try {
      final response = await _dio.get(
        '/chat/conversas',
        options: Options(headers: await _headers()),
      );
      final dados = response.data as List<dynamic>;
      _sincronizarComBackend(dados);
    } on DioException catch (e) {
      debugPrint('❌ [GET /chat/conversas] ${e.response?.statusCode}');
    }
  }

  void _sincronizarComBackend(List<dynamic> dados) {
    bool changed = false;

    for (final item in dados) {
      final solicitacaoId = item['solicitacao_id'] as int;
      final meuId = item['meu_id'] as int? ?? 0;
      final nomeOutroUsuario = item['nome_outro_usuario'] as String? ?? 'Usuário';
      final tituloItem = item['titulo_item'] as String? ?? '';
      final ultimaMensagem = item['ultima_mensagem'] as String? ?? '';
      final naoLidas = int.tryParse('${item['nao_lidas'] ?? 0}') ?? 0;
      final encerrada = item['encerrada'] as bool? ?? false;

      // Conversas encerradas ou abertas agora não geram notificação
      if (encerrada || _chatsAbertos.contains(solicitacaoId)) continue;

      // Sem mensagens não lidas → garante que a notificação local está como lida
      if (naoLidas == 0) {
        final idx = _lista.indexWhere((n) => n.solicitacaoId == solicitacaoId);
        if (idx >= 0 && !_lista[idx].lida) {
          _lista[idx] = _lista[idx].copyWith(lida: true);
          changed = true;
        }
        continue;
      }

      final idx = _lista.indexWhere((n) => n.solicitacaoId == solicitacaoId);
      if (idx >= 0) {
        if (_lista[idx].lida || _lista[idx].mensagem != ultimaMensagem) {
          _lista[idx] = AppNotificacao(
            id: _lista[idx].id,
            solicitacaoId: solicitacaoId,
            meuId: meuId,
            usuarioNome: nomeOutroUsuario,
            itemTitulo: tituloItem,
            mensagem: ultimaMensagem,
            lida: false,
            criadoEm: DateTime.now(),
          );
          changed = true;
        }
      } else {
        _lista.add(AppNotificacao(
          id: _nextId++,
          solicitacaoId: solicitacaoId,
          meuId: meuId,
          usuarioNome: nomeOutroUsuario,
          itemTitulo: tituloItem,
          mensagem: ultimaMensagem,
          criadoEm: DateTime.now(),
        ));
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  // ── Controle de chat aberto ───────────────────────────────────────────────

  /// Chamado quando o ChatScreen abre — suprime notificações e marca como lido.
  Future<void> abrirChat(int solicitacaoId) async {
    _chatsAbertos.add(solicitacaoId);
    await marcarComoLidaPorSolicitacao(solicitacaoId);
    // Avisa o backend que as mensagens foram lidas
    _marcarLidoNoBackend(solicitacaoId);
  }

  /// Chamado quando o ChatScreen fecha.
  void fecharChat(int solicitacaoId) {
    _chatsAbertos.remove(solicitacaoId);
  }

  Future<void> _marcarLidoNoBackend(int solicitacaoId) async {
    try {
      await _dio.patch(
        '/chat/$solicitacaoId/lido',
        options: Options(headers: await _headers()),
      );
    } on DioException catch (e) {
      debugPrint(
          '❌ [PATCH /chat/$solicitacaoId/lido] ${e.response?.statusCode}');
    }
  }

  // ── Estado local ──────────────────────────────────────────────────────────

  Future<void> marcarComoLidaPorSolicitacao(int solicitacaoId) async {
    bool changed = false;
    for (int i = 0; i < _lista.length; i++) {
      if (_lista[i].solicitacaoId == solicitacaoId && !_lista[i].lida) {
        _lista[i] = _lista[i].copyWith(lida: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> marcarComoLida(int notificacaoId) async {
    final idx = _lista.indexWhere((n) => n.id == notificacaoId);
    if (idx >= 0 && !_lista[idx].lida) {
      _lista[idx] = _lista[idx].copyWith(lida: true);
      notifyListeners();
    }
  }

  Future<void> marcarTodasComoLidas() async {
    bool changed = false;
    for (int i = 0; i < _lista.length; i++) {
      if (!_lista[i].lida) {
        _lista[i] = _lista[i].copyWith(lida: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> buscarLista({bool apenasNaoLidas = false}) async {
    await _buscarNaoLidas();
  }

  Future<void> atualizarContagem() async {
    await _buscarNaoLidas();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
