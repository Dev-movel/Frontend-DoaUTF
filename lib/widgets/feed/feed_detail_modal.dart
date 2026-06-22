import 'package:flutter/material.dart';
import '../../models/feed_item.dart';
import '../../services/solicitacao_service.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../mapa/modal_mapa_local.dart';

class FeedDetailModal {
  FeedDetailModal._();

  static Future<void> show(BuildContext context, FeedItem item) {
    return showDialog(
      context: context,
      builder: (_) => _FeedDetailDialog(item: item, parentContext: context),
    );
  }
}

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
  bool _isActionLoading = false;
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
    _obterUsuarioLogado();
  }

  Future<void> _obterUsuarioLogado() async {
    try {
      final user = await UsuarioService.instance.getMe();
      if (mounted) {
        setState(() {
          _meuId = user.id;
          _carregandoUsuario = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoUsuario = false);
      }
    }
  }

  void _exibirAlertaErro(String mensagem) {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _alternarInteresse() async {
    if (_isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      if (_solicitacaoId == null) {
        final novoId = await SolicitacaoService.instance.criarSolicitacao(item.id);
        if (mounted) {
          setState(() => _solicitacaoId = novoId);
        }
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(
            content: Text('Interesse registrado com sucesso! Aguarde o retorno do doador.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await SolicitacaoService.instance.cancelarSolicitacao(_solicitacaoId!);
        if (mounted) {
          setState(() => _solicitacaoId = null);
        }
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(
            content: Text('Sua solicitação de interesse foi cancelada.'),
            backgroundColor: AppColors.outline,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final erroMsg = e.toString();
      if (erroMsg.contains('próprio item') || erroMsg.contains('permissão')) {
        _exibirAlertaErro('Ação negada: Você não pode solicitar ou interagir com um item publicado por você mesmo.');
      } else {
        _exibirAlertaErro(erroMsg.replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool souODoador = _meuId != null && _meuId == item.doadorId;
    final bool estaDisponivel = _currentStatus.toLowerCase() == 'disponivel';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        color: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderImagem(fotos: item.fotos),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCategoriaETempo(item: item),
                    const SizedBox(height: 12),
                    Text(item.titulo, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          'Doado por ${item.doadorNome}',
                          style: AppTextStyles.body.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                    _BotaoLocalizacao(localizacao: item.localizacao),
                    const Divider(height: 32, color: AppColors.outlineVariant),
                    Text('Descrição', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 8),
                    Text(
                      item.descricao?.isNotEmpty == true ? item.descricao! : 'Nenhuma descrição fornecida pelo doador.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 24),
                    
                    if (_carregandoUsuario)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppColors.primaryContainer),
                        ),
                      )
                    else if (souODoador)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primaryContainer, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Este item foi publicado por você. Para gerenciar os interessados e agendamentos, acesse a aba "Dashboard".',
                                style: TextStyle(fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!estaDisponivel && _solicitacaoId == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Este item já mudou de estado e encontra-se: $_currentStatus.',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (_solicitacaoId != null)
                      _AcoesInteressadoRow(
                        isLoading: _isActionLoading,
                        onCancelar: _alternarInteresse,
                        onChat: () {
                          final nav = Navigator.of(context, rootNavigator: true);
                          nav.pop();
                          nav.pushNamed('/chat', arguments: {
                            'solicitacaoId': _solicitacaoId,
                            'meuId': _meuId ?? 0,
                            'nomeOutroUsuario': item.doadorNome,
                            'tituloItem': item.titulo,
                          });
                        },
                      )
                    else
                      _MeInteressaBtn(
                        isLoading: _isActionLoading,
                        onPressed: _alternarInteresse,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderImagem extends StatefulWidget {
  final List<String> fotos;
  const _HeaderImagem({required this.fotos});

  @override
  State<_HeaderImagem> createState() => _HeaderImagemState();
}

class _HeaderImagemState extends State<_HeaderImagem> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool temFotos = widget.fotos.isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          color: AppColors.containerHigh,
          child: !temFotos
              ? const Icon(Icons.image_not_supported_outlined, size: 52, color: AppColors.outline)
              : PageView.builder(
                  itemCount: widget.fotos.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.fotos[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 52, color: AppColors.outline),
                      ),
                    );
                  },
                ),
        ),
        
        Positioned(
          top: 12,
          right: 12,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        if (widget.fotos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.fotos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCategoriaETempo extends StatelessWidget {
  final FeedItem item;
  const _InfoCategoriaETempo({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            item.categoria.toUpperCase(),
            style: const TextStyle(fontSize: 11, color: AppColors.primaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        Text(item.tempoAtras, style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _BotaoLocalizacao extends StatelessWidget {
  final String localizacao;
  const _BotaoLocalizacao({required this.localizacao});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ModalMapaLocal.mostrar(context, localizacao: localizacao),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.primaryContainer),
            const SizedBox(width: 4),
            Text(
              localizacao,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primaryContainer,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeInteressaBtn extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _MeInteressaBtn({
    required this.isLoading,
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
            : const Icon(Icons.favorite_border, size: 20),
        label: Text(
          isLoading ? 'Enviando...' : 'Me Interessa!',
          style: AppTextStyles.button,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _AcoesInteressadoRow extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancelar;
  final VoidCallback onChat;

  const _AcoesInteressadoRow({
    required this.isLoading,
    required this.onCancelar,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onCancelar,
              icon: isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                isLoading ? 'Cancelando...' : 'Cancelar',
                style: AppTextStyles.button.copyWith(color: Colors.red.shade600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text('Conversar', style: AppTextStyles.button.copyWith(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}