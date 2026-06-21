import 'package:flutter/material.dart';
import '../models/notificacao.dart';
import '../models/usuario.dart';
import '../services/notificacao_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import 'agendamento_screen.dart';

class NotificacoesScreen extends StatefulWidget {
  final bool isDialog;

  const NotificacoesScreen({super.key, this.isDialog = false});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  bool _isLoading = true;
  List<Notificacao> _notificacoes = [];
  Usuario? _usuario;
  final Set<int> _tocadas = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final lista = await NotificacaoService.instance.listar(apenasNaoLidas: true);
      final usuario = await UsuarioService.instance.getMe();
      if (!mounted) return;
      setState(() {
        _notificacoes = lista;
        _usuario = usuario;
        _tocadas.clear();
      });
    } catch (e) {
      debugPrint('❌ [NotificacoesScreen] $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirNotificacao(Notificacao n) async {
    if (!_tocadas.contains(n.id)) {
      setState(() => _tocadas.add(n.id));
      await NotificacaoService.instance.marcarLida(n.id);
    }

    final itemId = n.dados['item_id'];
    final uid = _usuario?.id;
    if (uid == null || !mounted) return;

    switch (n.tipo) {
      case 'nova_solicitacao':
      case 'solicitacao_recusada':
        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      default:
        if (itemId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgendamentoScreen(
                itemId: int.parse(itemId.toString()),
                usuarioIdAtual: uid,
              ),
            ),
          );
        }
    }
  }

  Future<void> _marcarTodasLidas() async {
    await NotificacaoService.instance.marcarTodasLidas();
    if (!mounted) return;
    setState(() {
      _tocadas.addAll(_notificacoes.map((n) => n.id));
      _notificacoes.clear();
    });
  }

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    return 'há ${diff.inDays} dias';
  }

  IconData _iconePorTipo(String tipo) {
    switch (tipo) {
      case 'nova_solicitacao':         return Icons.person_add_outlined;
      case 'solicitacao_aceita':       return Icons.check_circle_outline;
      case 'solicitacao_recusada':     return Icons.cancel_outlined;
      case 'horario_sugerido':         return Icons.schedule;
      case 'disponibilidade_proposta': return Icons.event_available_outlined;
      case 'agendamento_confirmado':   return Icons.event_outlined;
      case 'agendamento_concluido':    return Icons.volunteer_activism;
      case 'agendamento_expirado':     return Icons.event_busy_outlined;
      default:                         return Icons.notifications_none;
    }
  }

  Color _corPorTipo(String tipo) {
    switch (tipo) {
      case 'solicitacao_aceita':
      case 'agendamento_confirmado':
      case 'agendamento_concluido':
        return Colors.green.shade600;
      case 'solicitacao_recusada':
      case 'agendamento_expirado':
        return Colors.red.shade600;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildDialogLayout();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Notificações',
          style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actions: [
          if (!_isLoading && _notificacoes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como lidas',
              onPressed: _marcarTodasLidas,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLista(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
    );
  }

  Widget _buildDialogLayout() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: AppColors.background,
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificações',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (!_isLoading && _notificacoes.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.done_all, color: AppColors.onSurface),
                      tooltip: 'Marcar todas como lidas',
                      onPressed: _marcarTodasLidas,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLista(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista({required EdgeInsets padding}) {
    if (_notificacoes.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.separated(
        padding: padding,
        itemCount: _notificacoes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildItem(_notificacoes[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Nenhuma notificação',
            style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Notificacao n) {
    final cor = _corPorTipo(n.tipo);
    final tocada = _tocadas.contains(n.id);

    return Material(
      color: tocada ? AppColors.surface : AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirNotificacao(n),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconePorTipo(n.tipo), color: cor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.mensagem,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: tocada ? FontWeight.normal : FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tempoRelativo(n.criadoEm),
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (!tocada)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
