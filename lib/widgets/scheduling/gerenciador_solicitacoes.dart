import 'package:flutter/material.dart';
import '../../services/solicitacao_service.dart';

class GerenciadorSolicitacoesWidget extends StatefulWidget {
  final int itemId;
  final VoidCallback onSolicitacaoAceita;

  const GerenciadorSolicitacoesWidget({
    super.key,
    required this.itemId,
    required this.onSolicitacaoAceita,
  });

  @override
  State<GerenciadorSolicitacoesWidget> createState() => _GerenciadorSolicitacoesWidgetState();
}

class _GerenciadorSolicitacoesWidgetState extends State<GerenciadorSolicitacoesWidget> {
  List<dynamic> _interessados = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      _isLoading = true; 
      _errorMessage = null;
    });
    try {
      await SolicitacaoService.instance.aceitarSolicitacao(solicitacaoId);
      if (!mounted) return;

      widget.onSolicitacaoAceita();
      setState(() {
        _isLoading = false;
        _interessados = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação aceita! Item reservado para agendamento.'),
          backgroundColor: Color(0xFF0D631B),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Não foi possível aceitar: ${e.toString()}";
          _isLoading = false;
        });
      }
      _carregarInteressados();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF0D631B))),
      );
    }

    if (_errorMessage != null) return const SizedBox.shrink();
    if (_interessados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Nenhuma solicitação pendente para este item.',
          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            'Solicitações de Interesse',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C19)),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _interessados.length,
          itemBuilder: (context, index) {
            final solicitacao = _interessados[index];
            final solicitante = solicitacao['solicitante'] ?? {};
            final nome = solicitante['nome'] ?? 'Usuário Interessado';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3ED),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C19)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deseja receber esta doação',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D631B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _aceitar(solicitacao['id']),
                    child: const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}