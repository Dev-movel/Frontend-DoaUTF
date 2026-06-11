import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart'; 
import '../../models/agendamento.dart';
import '../../services/agendamento_service.dart';
import '../../theme/app_colors.dart';
import 'agendamento_status_badge.dart';
import 'date_time_picker_helper.dart';

class AgendamentoSection extends StatefulWidget {
  final int itemId;
  final int usuarioId;
  final VoidCallback? onRefresh;

  const AgendamentoSection({
    super.key,
    required this.itemId,
    required this.usuarioId,
    this.onRefresh,
  });

  @override
  State<AgendamentoSection> createState() => _AgendamentoSectionState();
}

class _AgendamentoSectionState extends State<AgendamentoSection> {
  static final _fmt = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
  
  Agendamento? _agendamento;
  bool _loading = true;

  bool get _isReceptor => _agendamento != null && widget.usuarioId == _agendamento!.receptorId;
  bool get _isDoador => _agendamento != null && widget.usuarioId == _agendamento!.doadorId;
  bool get _isParticipante => _isDoador || _isReceptor;
  bool get _precisaConfirmar {
    if (_agendamento == null) return false;
    if (_isDoador) return !_agendamento!.confirmacaoDoador;
    if (_isReceptor) return !_agendamento!.confirmacaoReceptor;
    return false;
  }

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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarMensagem(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processarAcao(Future<void> Function() acao, {String mensagemSucesso = 'Ação realizada com sucesso!'}) async {
    setState(() => _loading = true);
    try {
      await acao();
      _mostrarMensagem(mensagemSucesso);
      await _carregarAgendamento();
      widget.onRefresh?.call();
    } catch (e) {
      _mostrarMensagem(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acaoSugerirHorario() async {
    final data = await DateTimePickerHelper.selecionarDataHora(context);  
    if (data == null) return;

    await _processarAcao(
      () => AgendamentoService.instance.sugerirHorario(widget.itemId, data),
      mensagemSucesso: 'Sugestão de horário enviada com sucesso!',
    );
  }

  Future<void> _acaoProporDisponibilidade() async {
    final data = await DateTimePickerHelper.selecionarDataHora(context);
    if (data == null) return;

    await _processarAcao(
      () => AgendamentoService.instance.proporDisponibilidade(widget.itemId, data),
      mensagemSucesso: 'Sua janela de disponibilidade foi salva!',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
      );
    }

    if (_agendamento == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          'O item consta como reservado, mas os detalhes logísticos ainda não foram inicializados pelo servidor.',
          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.containerHigh.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
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
                  color: AppColors.onSurface,
                  fontSize: 16,
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
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
              Text(
                _agendamento!.status == AgendamentoStatus.concluido
                  ? 'Horário em que a doação foi concluída:'
                  : 'Horário em Negociação:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.outline),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.primaryContainer),
                  const SizedBox(width: 8),
                  Text(_fmt.format(_agendamento!.dataHora!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onSurface)),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Nenhum horário definido ainda. Sugira um horário ou defina disponibilidade para o agendamento.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
                  onPressed: _acaoSugerirHorario,
                  isSecundario: true,
                ),
            ],

            if (_agendamento!.status == AgendamentoStatus.pendente && _agendamento!.dataHora != null) ...[
              if (_precisaConfirmar) ...[
                _ActionButton(
                  label: 'Confirmar Horário',
                  onPressed: () => _processarAcao(
                    () => AgendamentoService.instance.confirmarAgendamento(widget.itemId),
                    mensagemSucesso: 'Horário confirmado por ambas as partes!',
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (_isParticipante) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aguardando a confirmação do outro usuário.',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  'Apenas o doador ou o receptor deste agendamento pode confirmar o horário.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                  onPressed: _acaoProporDisponibilidade,
                  isSecundario: true,
                ),
            ],

            if (_agendamento!.status == AgendamentoStatus.confirmado && _isDoador)
              _ActionButton(
                label: 'Concluir Entrega',
                onPressed: () => _processarAcao(
                  () => AgendamentoService.instance.concluirEntrega(widget.itemId),
                  mensagemSucesso: 'Excelente! Entrega finalizada e registrada no ecossistema.',
                ),
              ),
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
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: isSecundario
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primaryContainer, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onPressed,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onPressed,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
    );
  }
}