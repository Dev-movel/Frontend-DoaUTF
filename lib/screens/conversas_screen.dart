import 'package:flutter/material.dart';
import '../models/conversa_item.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/main_app_bar.dart';

class ConversasScreen extends StatefulWidget {
  const ConversasScreen({super.key});

  @override
  State<ConversasScreen> createState() => _ConversasScreenState();
}

class _ConversasScreenState extends State<ConversasScreen> {
  List<ConversaItem> _conversas = [];
  bool _carregando = true;
  int _meuId = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final results = await Future.wait([
        ChatService.instance.buscarConversas(),
        UsuarioService.instance.getMe(),
      ]);
      if (!mounted) return;
      setState(() {
        _conversas = results[0] as List<ConversaItem>;
        _meuId = (results[1] as dynamic).id as int? ?? 0;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirChat(ConversaItem c) {
    NotificationService.instance.abrirChat(c.solicitacaoId);
    // Atualiza o badge local imediatamente
    setState(() {
      final idx = _conversas.indexWhere((x) => x.solicitacaoId == c.solicitacaoId);
      if (idx >= 0) {
        _conversas[idx] = ConversaItem(
          solicitacaoId: c.solicitacaoId,
          itemId: c.itemId,
          tituloItem: c.tituloItem,
          nomeOutroUsuario: c.nomeOutroUsuario,
          ultimaMensagem: c.ultimaMensagem,
          ultimaMensagemEm: c.ultimaMensagemEm,
          encerrada: c.encerrada,
          naoLidas: 0,
        );
      }
    });
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'solicitacaoId': c.solicitacaoId,
        'meuId': _meuId,
        'nomeOutroUsuario': c.nomeOutroUsuario,
        'tituloItem': c.tituloItem,
        'modoLeitura': c.encerrada,
      },
    ).then((_) => _carregar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const MainAppBar(activeRoute: '/conversas'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text('Conversas',
                style: AppTextStyles.headline.copyWith(fontSize: 22)),
          ),
          const Divider(height: 1),
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _carregar,
                    color: AppColors.primary,
                    child: _buildLista(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_conversas.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: AppColors.outline.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text('Nenhuma conversa ainda',
                    style: AppTextStyles.headline.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  'Quando alguém mostrar interesse em\num dos seus itens, a conversa aparecerá aqui.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final ativas = _conversas.where((c) => !c.encerrada).toList();
    final encerradas = _conversas.where((c) => c.encerrada).toList();

    return ListView(
      children: [
        if (ativas.isNotEmpty) ...[
          _Secao(titulo: 'Ativas'),
          ...ativas.map((c) => _CartaoConversa(
                conversa: c,
                onTap: () => _abrirChat(c),
              )),
        ],
        if (encerradas.isNotEmpty) ...[
          _Secao(titulo: 'Encerradas'),
          ...encerradas.map((c) => _CartaoConversa(
                conversa: c,
                onTap: () => _abrirChat(c),
              )),
        ],
      ],
    );
  }
}

// ── Seção (título de grupo) ────────────────────────────────────────────────

class _Secao extends StatelessWidget {
  final String titulo;
  const _Secao({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        titulo.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Cartão de conversa ─────────────────────────────────────────────────────

class _CartaoConversa extends StatelessWidget {
  final ConversaItem conversa;
  final VoidCallback onTap;
  const _CartaoConversa({required this.conversa, required this.onTap});

  String _tempoAtras(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final c = conversa;
    final nome = c.nomeOutroUsuario;
    final encerrada = c.encerrada;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: !encerrada && c.naoLidas > 0
              ? AppColors.primaryContainer.withOpacity(0.06)
              : null,
          border: Border(
            bottom: BorderSide(color: AppColors.outline.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: encerrada
                      ? AppColors.outline.withOpacity(0.3)
                      : AppColors.primary,
                  child: Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: encerrada ? AppColors.onSurfaceVariant : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (encerrada)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.outline.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                      child: const Icon(Icons.lock_outline,
                          size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nome,
                          style: AppTextStyles.input.copyWith(
                            fontWeight: !encerrada && c.naoLidas > 0
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: encerrada
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        _tempoAtras(c.ultimaMensagemEm),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 11,
                          color: !encerrada && c.naoLidas > 0
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.tituloItem,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      color: encerrada
                          ? AppColors.outline
                          : AppColors.primary,
                    ),
                  ),
                  if (c.ultimaMensagem != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      c.ultimaMensagem!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: !encerrada && c.naoLidas > 0
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontWeight: !encerrada && c.naoLidas > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Badge ou label encerrado
            if (!encerrada && c.naoLidas > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  c.naoLidas > 99 ? '99+' : '${c.naoLidas}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (encerrada)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.outline.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Encerrado',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
