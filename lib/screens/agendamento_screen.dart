import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/agendamento_service.dart';
import '../models/agendamento.dart';

class AgendamentoScreen extends StatefulWidget {
  final int itemId;
  final int usuarioIdAtual;
  final String? initialStatusAgendamento;
  final DateTime? initialDataAgendada;
  final int? doadorId;
  final int? receptorId;

  const AgendamentoScreen({
    super.key,
    required this.itemId,
    required this.usuarioIdAtual,
    this.initialStatusAgendamento,
    this.initialDataAgendada,
    this.doadorId,
    this.receptorId,
  });

  @override
  _AgendamentoScreenState createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final AgendamentoService _service = AgendamentoService.instance;
  bool _isLoading = true;
  Agendamento? _agendamento;

  bool get _isDoador {
    final doadorId = _agendamento?.doadorId ?? widget.doadorId;
    return widget.usuarioIdAtual == doadorId;
  }

  bool get _isReceptor {
    final receptorId = _agendamento?.receptorId ?? widget.receptorId;
    return widget.usuarioIdAtual == receptorId;
  }

  bool get _precisaConfirmar {
    if (_agendamento == null) return false;
    if (_isDoador) return !_agendamento!.confirmacaoDoador;
    if (_isReceptor) return !_agendamento!.confirmacaoReceptor;
    return false;
  }

  String get _statusAgendamento {
    return _agendamento?.status.name.toLowerCase() ?? widget.initialStatusAgendamento?.toLowerCase() ?? 'pendente';
  }

  DateTime? get _dataAgendada {
    return _agendamento?.dataHora ?? widget.initialDataAgendada;
  }

  @override
  void initState() {
    super.initState();
    _loadAgendamento();
  }

  Future<void> _loadAgendamento() async {
    setState(() => _isLoading = true);
    try {
      final agendamento = await _service.getByItem(widget.itemId);
      if (mounted) {
        setState(() => _agendamento = agendamento);
      }
    } catch (e) {
      debugPrint('Erro ao carregar agendamento: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final Color _surface = const Color(0xFFFAFAF5);
  final Color _primary = const Color(0xFF0D631B);
  final Color _onSurface = const Color(0xFF1A1C19);
  final Color _surfaceContainerLow = const Color(0xFFF3F3ED);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orangeAccent;
      case 'confirmado':
        return Colors.green;
      case 'concluido':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selecionarData(BuildContext context, {required bool isDoador}) async {
    if (!mounted) return;
    final BuildContext dialogContext = context;

    final DateTime? pickedDate = await showDatePicker(
      context: dialogContext,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: dialogContext,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime dataCompleta = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (dataCompleta.isBefore(DateTime.now())) {
      if (!mounted) return;
      _mostrarSnackBar('O horário não pode estar no passado.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isDoador) {
        await _service.proporDisponibilidade(widget.itemId, dataCompleta);
        if (!mounted) return;
        _mostrarSnackBar('Disponibilidade definida com sucesso!');
      } else {
        await _service.sugerirHorario(widget.itemId, dataCompleta);
        if (!mounted) return;
        _mostrarSnackBar('Horário sugerido com sucesso!');
      }
      await _loadAgendamento();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarAgendamento() async {
    setState(() => _isLoading = true);
    try {
      await _service.confirmarAgendamento(widget.itemId);
      _mostrarSnackBar('Agendamento confirmado!');
      await _loadAgendamento();
    } catch (e) {
      _mostrarSnackBar('Erro ao confirmar.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _concluirEntrega() async {
    setState(() => _isLoading = true);
    try {
      await _service.concluirEntrega(widget.itemId);
      _mostrarSnackBar('Entrega concluída com sucesso!');
      
      // Critério de Aceite: Redirecionar para avaliação
      // Navigator.pushReplacementNamed(context, '/avaliacao', arguments: widget.itemId);
    } catch (e) {
      _mostrarSnackBar('Erro ao concluir.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : _primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Logística e Agendamento'),
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status do Agendamento',
                              style: TextStyle(
                                  color: _onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_statusAgendamento)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusAgendamento.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(_statusAgendamento),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_dataAgendada != null) ...[
                          Text(
                            'Encontro marcado para:',
                            style: TextStyle(color: _onSurface.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(_dataAgendada!),
                            style: TextStyle(
                              color: _onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Nenhum horário definido ainda.',
                            style: TextStyle(
                              color: _onSurface,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  if (_statusAgendamento == 'pendente' && _dataAgendada == null && _isReceptor)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _selecionarData(context, isDoador: false),
                        child: const Text('Sugerir Horário'),
                      ),
                    ),

                  if (_statusAgendamento == 'pendente' && _dataAgendada == null && _isDoador)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _selecionarData(context, isDoador: true),
                        child: const Text('Definir Disponibilidade'),
                      ),
                    ),

                  const SizedBox(height: 12),
                  
                  if (_statusAgendamento == 'pendente' && _dataAgendada != null && _precisaConfirmar)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _confirmarAgendamento,
                        child: const Text('Confirmar Horário'),
                      ),
                    ),

                  if (_statusAgendamento == 'pendente' && _dataAgendada != null && !_precisaConfirmar)
                    Text(
                      'Aguardando confirmação do outro participante.',
                      style: TextStyle(color: _onSurface.withOpacity(0.7)),
                    ),

                  if (_statusAgendamento == 'confirmado' && _isDoador)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _concluirEntrega,
                        child: const Text('Concluir Entrega'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}