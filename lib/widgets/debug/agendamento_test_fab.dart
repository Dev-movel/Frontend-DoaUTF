import 'package:flutter/material.dart';
import '../../screens/agendamento_screen.dart';
import '../../services/usuario_service.dart';

/// Widget de debug para testar AgendamentoScreen
/// Remove isto quando o Dashboard for implementado
class AgendamentoTestFAB extends StatefulWidget {
  const AgendamentoTestFAB({super.key});

  @override
  State<AgendamentoTestFAB> createState() => _AgendamentoTestFABState();
}

class _AgendamentoTestFABState extends State<AgendamentoTestFAB> {
  final _itemIdController = TextEditingController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final user = await UsuarioService.instance.getMe();
      if (mounted) setState(() => _currentUserId = user.id);
    } catch (e) {
      debugPrint('Erro ao carregar usuário atual: $e');
    }
  }

  void _abrirAgendamento() {
    final itemId = int.tryParse(_itemIdController.text);
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um itemId válido')),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não carregado')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AgendamentoScreen(
          itemId: itemId,
          usuarioIdAtual: _currentUserId!,
        ),
      ),
    );

    Navigator.of(context).pop(); // Fecha o modal
    _itemIdController.clear();
  }

  @override
  void dispose() {
    _itemIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.redAccent,
      tooltip: 'Debug: Abrir Agendamento',
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('🧪 Teste de Agendamento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuário atual: $_currentUserId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _itemIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Item ID',
                    border: OutlineInputBorder(),
                    hintText: 'Digite o ID do item',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _abrirAgendamento,
                child: const Text('Abrir'),
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.bug_report),
    );
  }
}
