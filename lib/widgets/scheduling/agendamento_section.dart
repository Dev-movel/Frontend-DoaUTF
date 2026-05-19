import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart'; 
import '../../models/agendamento.dart';
import '../../services/agendamento_service.dart';
import 'agendamento_status_badge.dart';
import 'date_time_picker_helper.dart';

class AgendamentoSection extends StatefulWidget {
  final int itemId;
  final String itemStatus;
  final int doadorId;
  final int usuarioId;

  const AgendamentoSection({
    super.key,
    required this.itemId,
    required this.itemStatus,
    required this.doadorId,
    required this.usuarioId,
  });

  @override
  State<AgendamentoSection> createState() => _AgendamentoSectionState();
}

class _AgendamentoSectionState extends State<AgendamentoSection> {
  static final _fmt = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
  
  Agendamento? _agendamento;
  bool _loading = true;

  bool get _isDoador => widget.usuarioId == widget.doadorId;
  bool get _isReceptor => _agendamento != null && widget.usuarioId == _agendamento!.receptorId;
  bool get _isParticipante => _isDoador || _isReceptor;
  bool get _precisaConfirmar {
    if (_agendamento == null) return false;
    if (_isDoador) return !_agendamento!.confirmacaoDoador;
    if (_isReceptor) return !_agendamento!.confirmacaoReceptor;
    return false;
  }

  final Color _primary = const Color(0xFF0D631B);
  final Color _surfaceContainerLow = const Color(0xFFF3F3ED);

  @override
  void initState() {
    super.initState();
    _carregarAgendamento();
  }

  Future<void> _carregarAgendamento() async {
    try {
      final agendamento = await AgendamentoService.instance.getByItem(widget.itemId);
      if (mounted) setState(() => _agendamento = agendamento);
    } catch (e) {
      // Erro tratado silenciosamente para manter o fluxo
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarMensagem(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : _primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processarAcao(Future<void> Function() acao) async {
    setState(() => _loading = true);
    try {
      await acao();
      await _carregarAgendamento();
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        _mostrarMensagem('A data e hora sugeridas não podem estar no passado.', isError: true);
      } else if (e.response?.statusCode == 403) {
        _mostrarMensagem('Ação proibida: você não faz parte deste agendamento.', isError: true);
      } else {
        _mostrarMensagem('Erro ao processar: ${e.message}', isError: true);
      }
    } catch (e) {
      _mostrarMensagem('Erro inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acaoSugerirHorario() async {
    final data = await DateTimePickerHelper.selecionarDataHora(context);
    if (data == null) return;

    await _processarAcao(() => 
      AgendamentoService.instance.sugerirHorario(widget.itemId, data)
    );
  }

  Future<void> _acaoProporDisponibilidade() async {
    final data = await DateTimePickerHelper.selecionarDataHora(context);
    if (data == null) return;

    await _processarAcao(() => 
      AgendamentoService.instance.proporDisponibilidade(widget.itemId, data)
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D631B)),
        ),
      );
    }

    if (_agendamento == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text(
          '⚠️ O status atualizou para reservado, mas o backend não retornou o agendamento.\n\nVerifique se a rota GET /itens/{id}/agendamento está funcionando ou se o agendamento foi realmente criado no banco de dados.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
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
              const Text(
                'Logística de Retirada',
                style: TextStyle(
                  color: Color(0xFF1A1C19),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_agendamento != null)
                AgendamentoStatusBadge(status: _agendamento!.status),
            ],
          ),
          const SizedBox(height: 16),

          if (_agendamento == null) ...[
            Text(
              'Item reservado! Inicie o agendamento para combinar a entrega.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            if (!_isDoador)
              _ActionButton(
                label: 'Sugerir Horário',
                onPressed: _acaoSugerirHorario,
              ),
            if (_isDoador)
              _ActionButton(
                label: 'Definir Disponibilidade',
                isSecundario: true,
                onPressed: _acaoProporDisponibilidade,
              ),
          ] else ...[
            if (_agendamento!.dataHora != null) ...[
              const Text('Horário Sugerido:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(_fmt.format(_agendamento!.dataHora!)),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Nenhum horário definido ainda. Sugira um horário ou defina disponibilidade para o agendamento.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              if (_isDoador)
                _ActionButton(
                  label: 'Definir Disponibilidade',
                  isSecundario: true,
                  onPressed: _acaoProporDisponibilidade,
                ),
              if (_isReceptor)
                _ActionButton(
                  label: 'Sugerir Horário',
                  isSecundario: true,
                  onPressed: _acaoSugerirHorario,
                ),
            ],

            if (_agendamento!.status == AgendamentoStatus.pendente && _agendamento!.dataHora != null) ...[
              if (_precisaConfirmar) ...[
                _ActionButton(
                  label: 'Confirmar Horário',
                  onPressed: () => _processarAcao(() => AgendamentoService.instance.confirmarAgendamento(widget.itemId)),
                ),
                const SizedBox(height: 8),
              ] else if (_isParticipante) ...[
                Text(
                  'Aguardando confirmação do outro participante.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
              ] else ...[
                Text(
                  'Apenas o doador ou o receptor deste agendamento pode confirmar o horário.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
              ],
              if (!_isDoador)
                _ActionButton(
                  label: 'Sugerir Outro Horário',
                  isSecundario: true,
                  onPressed: _acaoSugerirHorario,
                ),
              if (_isDoador)
                _ActionButton(
                  label: 'Definir Outro Horário',
                  isSecundario: true,
                  onPressed: _acaoProporDisponibilidade,
                ),
            ],

            if (_agendamento!.status == AgendamentoStatus.confirmado && _isDoador) ...[
               _ActionButton(
                label: 'Concluir Entrega',
                onPressed: () => _processarAcao(() => AgendamentoService.instance.concluirEntrega(widget.itemId)),
              ),
            ]
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecundario;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isSecundario = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF0D631B);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isSecundario
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }
}