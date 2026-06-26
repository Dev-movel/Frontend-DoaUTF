import 'package:flutter/material.dart';
import '../../services/solicitacao_service.dart';
import '../../theme/app_colors.dart';

class ModalInteressadosBottomSheet extends StatefulWidget {
  final int itemId;
  final int meuId;
  final String tituloItem;
  final Function(int itemId)? onSolicitacaoAceitaComSucesso;
  final VoidCallback onSolicitacaoAceita;

  const ModalInteressadosBottomSheet({
    super.key,
    required this.itemId,
    required this.meuId,
    required this.tituloItem,
    this.onSolicitacaoAceitaComSucesso,
    required this.onSolicitacaoAceita,
  });

  @override
  State<ModalInteressadosBottomSheet> createState() => _ModalInteressadosBottomSheetState();
}

class _ModalInteressadosBottomSheetState extends State<ModalInteressadosBottomSheet> {
  List<dynamic> _interessados = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _solicitacaoAceitandoId;

  @override
  void initState() {
    super.initState();
    _carregarInteressados();
  }

  Future<void> _carregarInteressados() async {
    try {
      final dados = await SolicitacaoService.instance.buscarSolicitacoesDoItem(widget.itemId);
      if (mounted) {
        setState(() {
          _interessados = dados.where((s) => s['status'] == 'pendente').toList();
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _aceitar(int solicitacaoId) async {
    setState(() {
      _solicitacaoAceitandoId = solicitacaoId;
    });

    try {
      await SolicitacaoService.instance.aceitarSolicitacao(solicitacaoId);
      
      if (!mounted) return;

      widget.onSolicitacaoAceitaComSucesso?.call(widget.itemId);
      widget.onSolicitacaoAceita();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação aceita com sucesso! ✓'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao aceitar: ${e.toString().replaceAll("Exception: ", "")}';
        _solicitacaoAceitandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        ),
      );
      await _carregarInteressados();
    }
  }

  void _abrirChat(int solicitacaoId, String nomeSolicitante) {
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop(); // fecha o bottom sheet
    nav.pushNamed('/chat', arguments: {
      'solicitacaoId': solicitacaoId,
      'meuId': widget.meuId,
      'nomeOutroUsuario': nomeSolicitante,
      'tituloItem': widget.tituloItem,
    });
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return '';
    try {
      final dt = DateTime.parse(dataIso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Divider(color: AppColors.outlineVariant),
            Flexible(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_interessados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.outline.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'Nenhuma solicitação pendente para este item no momento.',
              style: TextStyle(color: AppColors.outline, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _interessados.length,
      itemBuilder: (context, index) {
        final solicitacao = _interessados[index];
        final solicitante = solicitacao['solicitante'] ?? {};
        
        final nome = solicitante['nome'] ?? solicitacao['solicitante_nome'] ?? 'Usuário Interessado';
        final dataCriacao = _formatarData(solicitacao['criado_em'] ?? solicitacao['data_solicitacao']);
        final solicitacaoId = solicitacao['id'] as int;        
        final isProcessando = _solicitacaoAceitandoId == solicitacaoId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.containerHigh.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryContainer.withOpacity(0.12),
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppColors.primaryContainer, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dataCriacao.isNotEmpty ? 'Pedido em $dataCriacao' : 'Aguardando sua escolha',
                                style: const TextStyle(color: AppColors.outline, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isProcessando 
                          ? Colors.grey.shade400 
                          : AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isProcessando ? null : () => _aceitar(solicitacaoId),
                    child: isProcessando
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isProcessando ? null : () => _abrirChat(solicitacaoId, nome),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Conversar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isProcessando ? Colors.grey : AppColors.primaryContainer,
                    side: BorderSide(
                      color: isProcessando ? Colors.grey : AppColors.primaryContainer,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}