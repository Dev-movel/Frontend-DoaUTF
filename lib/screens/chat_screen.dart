import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ChatScreen extends StatefulWidget {
  final int solicitacaoId;
  final int meuId;
  final String nomeOutroUsuario;
  final String tituloItem;
  final bool modoLeitura;

  const ChatScreen({
    super.key,
    required this.solicitacaoId,
    required this.meuId,
    required this.nomeOutroUsuario,
    required this.tituloItem,
    this.modoLeitura = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final List<ChatMessage> _mensagens = [];

  StreamSubscription<dynamic>? _sub;
  bool _carregando = true;
  bool _conectado = false;
  bool _enviando = false;
  bool _appEmFoco = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.abrirChat(widget.solicitacaoId);
    _inicializar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appEmFoco = state == AppLifecycleState.resumed;
    if (_appEmFoco) {
      NotificationService.instance.abrirChat(widget.solicitacaoId);
    }
  }

  Future<void> _inicializar() async {
    final historico =
        await ChatService.instance.buscarHistorico(widget.solicitacaoId);
    if (!mounted) return;
    setState(() {
      _mensagens.addAll(historico);
      _carregando = false;
    });
    _rolarParaBaixo();

    // Modo leitura: não conecta WebSocket
    if (widget.modoLeitura) return;

    final channel = await ChatService.instance.conectar(widget.solicitacaoId);
    if (!mounted) return;
    if (channel == null) return;

    setState(() => _conectado = true);

    _sub = channel.stream.listen(
      (data) {
        final msg = ChatMessage.tryFromWebSocket(data);
        if (msg == null || !mounted) return;

        setState(() {
          _mensagens.removeWhere(
              (m) => m.enviandoLocalmente && m.conteudo == msg.conteudo);
          _mensagens.add(msg);
        });
        _rolarParaBaixo();

        // Se a mensagem é do outro usuário e o chat está visível, marca como lida
        if (msg.remetenteId != widget.meuId && _appEmFoco) {
          NotificationService.instance.abrirChat(widget.solicitacaoId);
        }
      },
      onDone: () {
        if (mounted) setState(() => _conectado = false);
      },
      onError: (_) {
        if (mounted) setState(() => _conectado = false);
      },
      cancelOnError: false,
    );
  }

  void _rolarParaBaixo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _inputController.text.trim();
    if (texto.isEmpty || _enviando) return;

    if (!_conectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem conexão com o servidor. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    _inputController.clear();

    setState(() => _mensagens.add(ChatMessage(
          remetenteId: widget.meuId,
          conteudo: texto,
          criadoEm: DateTime.now(),
          enviandoLocalmente: true,
        )));
    _rolarParaBaixo();

    ChatService.instance.enviar(texto);
    setState(() => _enviando = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.fecharChat(widget.solicitacaoId);
    _sub?.cancel();
    ChatService.instance.fechar();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.modoLeitura) _BannerEncerrado(),
          if (!widget.modoLeitura && !_carregando && !_conectado)
            _BannerDesconectado(
              onReconectar: () async {
                final ch =
                    await ChatService.instance.conectar(widget.solicitacaoId);
                if (!mounted) return;
                if (ch != null) setState(() => _conectado = true);
              },
            ),
          Expanded(child: _buildLista()),
          if (!widget.modoLeitura)
            _InputBar(controller: _inputController, onEnviar: _enviar),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.nomeOutroUsuario.isNotEmpty
                  ? widget.nomeOutroUsuario[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nomeOutroUsuario,
                  style: AppTextStyles.input
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  widget.tituloItem,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.outline.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildLista() {
    if (_carregando) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_mensagens.isEmpty) {
      return _EmptyState(nomeOutroUsuario: widget.nomeOutroUsuario);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _mensagens.length,
      itemBuilder: (context, i) {
        final msg = _mensagens[i];
        final isMeu = msg.remetenteId == widget.meuId;
        final mostrarData = i == 0 ||
            msg.criadoEm
                    .difference(_mensagens[i - 1].criadoEm)
                    .inMinutes
                    .abs() >
                10;
        return Column(
          children: [
            if (mostrarData) _DataSeparador(data: msg.criadoEm),
            _BubbleMensagem(mensagem: msg, isMeu: isMeu),
          ],
        );
      },
    );
  }
}

// ── Banner de conversa encerrada ──────────────────────────────────────────

class _BannerEncerrado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.outline.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Esta conversa foi encerrada.',
            style: AppTextStyles.label.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner de desconexão ──────────────────────────────────────────────────

class _BannerDesconectado extends StatelessWidget {
  final VoidCallback onReconectar;
  const _BannerDesconectado({required this.onReconectar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Sem conexão em tempo real.',
                style: TextStyle(fontSize: 12, color: Colors.orange)),
          ),
          TextButton(
            onPressed: onReconectar,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Reconectar',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Separador de data ─────────────────────────────────────────────────────

class _DataSeparador extends StatelessWidget {
  final DateTime data;
  const _DataSeparador({required this.data});

  String _label() {
    final agora = DateTime.now();
    final local = data.toLocal();
    if (local.year == agora.year &&
        local.month == agora.month &&
        local.day == agora.day) {
      return 'Hoje';
    }
    final ontem = agora.subtract(const Duration(days: 1));
    if (local.year == ontem.year &&
        local.month == ontem.month &&
        local.day == ontem.day) {
      return 'Ontem';
    }
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(
                  color: AppColors.outline.withOpacity(0.3), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_label(),
                style: AppTextStyles.label.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w500,
                    fontSize: 10)),
          ),
          Expanded(
              child: Divider(
                  color: AppColors.outline.withOpacity(0.3), height: 1)),
        ],
      ),
    );
  }
}

// ── Bubble de mensagem ────────────────────────────────────────────────────

class _BubbleMensagem extends StatelessWidget {
  final ChatMessage mensagem;
  final bool isMeu;
  const _BubbleMensagem({required this.mensagem, required this.isMeu});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMeu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMeu ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMeu ? 16 : 4),
            bottomRight: Radius.circular(isMeu ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMeu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem.conteudo,
              style: AppTextStyles.body.copyWith(
                color: isMeu ? Colors.white : AppColors.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hora(mensagem.criadoEm),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMeu ? Colors.white70 : AppColors.onSurfaceVariant,
                  ),
                ),
                if (isMeu && mensagem.enviandoLocalmente) ...[
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hora(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String nomeOutroUsuario;
  const _EmptyState({required this.nomeOutroUsuario});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.outline.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Inicie a conversa',
                style: AppTextStyles.headline.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Você e $nomeOutroUsuario ainda não trocaram\nmensagens. Diga olá!',
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de input ────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;
  const _InputBar({required this.controller, required this.onEnviar});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.outline.withOpacity(0.15))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onEnviar(),
                textInputAction: TextInputAction.send,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: AppTextStyles.input,
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem...',
                  hintStyle: AppTextStyles.hint,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onEnviar,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child:
                      Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}