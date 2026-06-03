import 'package:flutter/material.dart';
import '../../models/feed_item.dart';
import '../../services/solicitacao_service.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../scheduling/agendamento_section.dart';
import '../scheduling/gerenciador_solicitacoes.dart';
import '../mapa/modal_mapa_local.dart'; // ← único import adicionado

class FeedDetailModal {
  FeedDetailModal._();

  static Future<void> show(BuildContext context, FeedItem item) {
    return showDialog(
      context: context,
      builder: (_) => _FeedDetailDialog(item: item, parentContext: context),
    );
  }
}

// ── Dialog principal ────────────────────────────────────────────────────────

class _FeedDetailDialog extends StatefulWidget {
  final FeedItem item;
  final BuildContext parentContext;

  const _FeedDetailDialog({
    required this.item,
    required this.parentContext,
  });

  @override
  State<_FeedDetailDialog> createState() => _FeedDetailDialogState();
}

class _FeedDetailDialogState extends State<_FeedDetailDialog> {
  bool _isLoading = false;
  bool _carregandoUsuario = true;
  int? _solicitacaoId;
  int? _meuId;

  late String _currentStatus;

  FeedItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _solicitacaoId = item.solicitacaoId;
    _currentStatus = item.status;
    _carregarMeuId();
    _atualizarSolicitacaoAtiva();
  }

  Future<void> _carregarMeuId() async {
    try {
      final user = await UsuarioService.instance.getMe();
      if (mounted) setState(() { _meuId = user.id; _carregandoUsuario = false; });
    } catch (_) {
      if (mounted) setState(() => _carregandoUsuario = false);
    }
  }

  Future<void> _atualizarSolicitacaoAtiva() async {
    try {
      final solicitacoes = await SolicitacaoService.instance.buscarMinhasSolicitacoes();
      if (!mounted) return;
      setState(() { _solicitacaoId = solicitacoes[item.id]; });
    } catch (_) {}
  }

  Future<void> _meInteressa() async {
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() => _isLoading = true);
    try {
      final id = await SolicitacaoService.instance.criarSolicitacao(item.id);
      if (!mounted) return;
      setState(() => _solicitacaoId = id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada com sucesso!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on SolicitacaoException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarSolicitacao() async {
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() => _isLoading = true);
    try {
      await SolicitacaoService.instance.cancelarSolicitacao(_solicitacaoId!);
      if (!mounted) return;
      setState(() => _solicitacaoId = null);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Solicitação cancelada.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on SolicitacaoException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoUsuario) {
      return const Center(child: CircularProgressIndicator());
    }

    final int usuarioLogadoId = _meuId ?? 0;
    final bool isDoador = usuarioLogadoId == item.doadorId;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 960,
        height: 640,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImagemGaleria(fotos: item.fotos),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DoadorHeader(item: item, onClose: () => Navigator.of(context).pop()),
                      const SizedBox(height: 16),
                      _Badges(categoria: item.categoria, status: _currentStatus),
                      const SizedBox(height: 10),
                      Text(
                        item.titulo,
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.descricao ?? 'Sem descrição disponível.',
                        style: AppTextStyles.body.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      // ← _InfoCards agora recebe o context para abrir o mapa
                      _InfoCards(item: item, context: context),
                      const SizedBox(height: 16),
                      const _DicaSeguranca(),
                      const SizedBox(height: 24),
                      if (!_carregandoUsuario && _meuId != item.doadorId)
                        _MeInteressaBtn(
                          isLoading: _isLoading,
                          cancelar: _solicitacaoId != null,
                          onPressed: _solicitacaoId != null
                              ? _cancelarSolicitacao
                              : _meInteressa,
                        ),
                      if (isDoador && _currentStatus.toLowerCase() == 'disponivel') ...[
                        const SizedBox(height: 24),
                        GerenciadorSolicitacoesWidget(
                          itemId: item.id,
                          onSolicitacaoAceita: () {
                            setState(() => _currentStatus = 'reservado');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Solicitação aceita! O painel de agendamento foi liberado abaixo.'),
                                backgroundColor: Color(0xFF0D631B),
                              ),
                            );
                          },
                        ),
                      ],
                      if (_currentStatus.toLowerCase() == 'reservado' ||
                          _currentStatus.toLowerCase() == 'agendado') ...[
                        const SizedBox(height: 24),
                        AgendamentoSection(
                          itemId: item.id,
                          itemStatus: _currentStatus,
                          doadorId: item.doadorId ?? 0,
                          usuarioId: usuarioLogadoId,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carrossel de imagens lateral esquerda ──────────────────────────────────

class _ImagemGaleria extends StatefulWidget {
  final List<String> fotos;
  const _ImagemGaleria({required this.fotos});

  @override
  State<_ImagemGaleria> createState() => _ImagemGaleriaState();
}

class _ImagemGaleriaState extends State<_ImagemGaleria> {
  late final PageController _pageController;
  int _pagina = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _ir(int delta) {
    final destino = (_pagina + delta).clamp(0, widget.fotos.length - 1);
    _pageController.animateToPage(
      destino,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotos;

    return SizedBox(
      width: 480,
      child: Stack(
        fit: StackFit.expand,
        children: [
          fotos.isEmpty
              ? _Placeholder()
              : PageView.builder(
                  controller: _pageController,
                  itemCount: fotos.length,
                  onPageChanged: (i) => setState(() => _pagina = i),
                  itemBuilder: (_, i) => Image.network(
                    fotos[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _Placeholder(),
                  ),
                ),
          if (fotos.length > 1 && _pagina > 0)
            Positioned(
              left: 8, top: 0, bottom: 0,
              child: Center(child: _NavBtn(icon: Icons.chevron_left, onTap: () => _ir(-1))),
            ),
          if (fotos.length > 1 && _pagina < fotos.length - 1)
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: Center(child: _NavBtn(icon: Icons.chevron_right, onTap: () => _ir(1))),
            ),
          if (fotos.length > 1)
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(fotos.length, (i) {
                  final ativo = i == _pagina;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: ativo ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: ativo ? AppColors.primary : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.containerHigh,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.outline, size: 64),
      ),
    );
  }
}

// ── Header do doador ────────────────────────────────────────────────────────

class _DoadorHeader extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onClose;
  const _DoadorHeader({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final inicial = item.doadorNome.isNotEmpty
        ? item.doadorNome[0].toUpperCase()
        : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: Text(
            inicial,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.doadorNome, style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700)),
              Text('Publicado há ${item.tempoAtras}', style: AppTextStyles.subtitle),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
          tooltip: 'Fechar',
        ),
      ],
    );
  }
}

// ── Badges ──────────────────────────────────────────────────────────────────

class _Badges extends StatelessWidget {
  final String categoria;
  final String status;
  const _Badges({required this.categoria, required this.status});

  String get _label {
    switch (status.toLowerCase()) {
      case 'reservado': return 'RESERVADO';
      case 'doado':     return 'DOADO';
      case 'agendado':  return 'AGENDADO';
      default:          return 'DISPONÍVEL';
    }
  }

  Color get _color {
    switch (status.toLowerCase()) {
      case 'reservado': return Colors.orange;
      case 'doado':     return Colors.grey;
      case 'agendado':  return const Color(0xFF0D631B);
      default:          return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(20)),
          child: Text(_label, style: AppTextStyles.badge.copyWith(fontSize: 10, color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.secondaryFixed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            categoria.toUpperCase(),
            style: AppTextStyles.badge.copyWith(fontSize: 10, color: AppColors.onSecondaryContainer),
          ),
        ),
      ],
    );
  }
}

// ── Cards de ESTADO e LOCAL ─────────────────────────────────────────────────
// Só o card LOCAL virou botão — visual idêntico ao original.

class _InfoCards extends StatelessWidget {
  final FeedItem item;
  final BuildContext context;
  const _InfoCards({required this.item, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        // Card ESTADO — sem alteração
        Expanded(
          child: _InfoCard(
            icone: Icons.shield_outlined,
            rotulo: 'ESTADO',
            valor: item.estadoLabel,
          ),
        ),
        const SizedBox(width: 12),
        // Card LOCAL — agora é clicável e abre o mapa
        Expanded(
          child: _InfoCardBotao(
            icone: Icons.location_on_outlined,
            rotulo: 'LOCAL',
            valor: item.localizacao,
            onTap: () => ModalMapaLocal.mostrar(
              context,
              localizacao: item.localizacao,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card estático — igual ao original
class _InfoCard extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  const _InfoCard({required this.icone, required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: AppTextStyles.label.copyWith(color: AppColors.outline, letterSpacing: 0.8)),
                Text(valor,  style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card clicável — mesmo visual, com InkWell e indicador de mapa
class _InfoCardBotao extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final VoidCallback onTap;
  const _InfoCardBotao({
    required this.icone,
    required this.rotulo,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icone, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo, style: AppTextStyles.label.copyWith(color: AppColors.outline, letterSpacing: 0.8)),
                    Text(
                      valor,
                      style: AppTextStyles.input.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,        // texto na cor primária indica que é clicável
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Seta pequena reforça que é interativo
              const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dica de segurança ───────────────────────────────────────────────────────

class _DicaSeguranca extends StatelessWidget {
  const _DicaSeguranca();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Dica de Segurança: ',
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'Nunca realize pagamentos por itens gratuitos.',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botão Me Interessa ──────────────────────────────────────────────────────

class _MeInteressaBtn extends StatelessWidget {
  final bool isLoading;
  final bool cancelar;
  final VoidCallback onPressed;
  const _MeInteressaBtn({
    required this.isLoading,
    required this.cancelar,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Icon(cancelar ? Icons.cancel_outlined : Icons.chat_bubble_outline, size: 20),
        label: Text(
          isLoading
              ? (cancelar ? 'Cancelando...' : 'Enviando...')
              : (cancelar ? 'Cancelar Solicitação' : 'Me Interessa!'),
          style: AppTextStyles.button,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cancelar ? Colors.red.shade600 : AppColors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}