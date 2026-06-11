import 'package:flutter/material.dart';
import '../models/doacao.dart';
import '../theme/app_colors.dart';
import '../services/solicitacao_service.dart';
import '../services/agendamento_service.dart';
import '../services/usuario_service.dart';
import 'status_badge.dart';

class DonationCard extends StatefulWidget {
  final Doacao doacao;
  final VoidCallback onRefresh;

  const DonationCard({super.key, required this.doacao, required this.onRefresh});

  @override
  State<DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  bool _isActionLoading = false;
  String? _receptorNome;

  @override
  void initState() {
    super.initState();
    _loadReceptorIfNeeded();
  }

  Future<void> _loadReceptorIfNeeded() async {
    final statusNormalizado = widget.doacao.status.toLowerCase();
    final needsFetch = statusNormalizado.contains('doado') || statusNormalizado.contains('conclu') || widget.doacao.agendamentoAtivo?.status == 'concluido';
    if (!needsFetch) return;

    try {
      final ag = await AgendamentoService.instance.getByItem(widget.doacao.id);
      if (ag == null) return;
      final usuario = await UsuarioService.instance.getUsuarioById(ag.receptorId);
      if (!mounted) return;
      setState(() => _receptorNome = usuario.nome);
    } catch (_) {
      // falha silenciosa; não bloquear UI
    }
  }

  String _formatDateTime(DateTime dt) {
    final localDt = dt.toLocal();
    final day = localDt.day.toString().padLeft(2, '0');
    final month = localDt.month.toString().padLeft(2, '0');
    final year = localDt.year;
    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  void _abrirModalInteressados() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: SolicitacaoService.instance.buscarSolicitacoesDoItem(widget.doacao.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ),
                  );
                }

                final interessados = snapshot.data ?? [];
                if (interessados.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhuma solicitação ativa encontrada.')));
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Interessados nesta Doação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: interessados.length,
                        itemBuilder: (context, index) {
                          final item = interessados[index];
                          final solicitante = item['solicitante'] ?? {};
                          final nome = solicitante['nome'] ?? item['solicitante_nome'] ?? item['nome'] ?? 'Usuário Interessado';
                          final solicitacaoId = item['id'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryContainer.withOpacity(0.15),
                              child: Text((nome?.isNotEmpty == true ? nome![0].toUpperCase() : 'U'), style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(nome ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text((solicitante['whatsapp'] ?? item['solicitante_whatsapp']) != null ? 'WhatsApp: ${solicitante['whatsapp'] ?? item['solicitante_whatsapp']}' : 'Pedido em: ${item['criado_em'] != null ? _formatDateTime(DateTime.parse(item['criado_em'])) : ""} '),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isActionLoading ? null : () async {
                                Navigator.pop(context);
                                _executarAcaoLogistica(() => SolicitacaoService.instance.aceitarSolicitacao(solicitacaoId), 'Receptor selecionado! Agendamento iniciado.');
                              },
                              child: const Text('Doar para este'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleProporDisponibilidade() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (data == null) return;

    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );
    if (hora == null) return;

    final dataHoraFinal = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);

    _executarAcaoLogistica(
      () => AgendamentoService.instance.proporDisponibilidade(widget.doacao.id, dataHoraFinal),
      'Sua disponibilidade foi registrada! Aguardando o receptor.',
    );
  }

  Future<void> _executarAcaoLogistica(Future<dynamic> Function() chamada, String mensagemSucesso) async {
    setState(() => _isActionLoading = true);
    try {
      await chamada();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemSucesso), backgroundColor: Colors.green),
        );
      }
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusNormalizado = widget.doacao.status.toLowerCase();
    final possuiInteressados = widget.doacao.quantidadeSolicitacoesPendentes > 0;

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.containerHigh,
                    borderRadius: BorderRadius.circular(8),
                    image: widget.doacao.fotoUrl != null
                        ? DecorationImage(image: NetworkImage(widget.doacao.fotoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: widget.doacao.fotoUrl == null
                      ? const Icon(Icons.image_not_supported, color: AppColors.outline)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: widget.doacao.status),
                          if (statusNormalizado == 'disponivel' && possuiInteressados)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.shade600, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                '${widget.doacao.quantidadeSolicitacoesPendentes} Interessado(s)',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.doacao.titulo,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isActionLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: LinearProgressIndicator(color: AppColors.primary)),
              ),
            if ((statusNormalizado.contains('doado') || statusNormalizado.contains('conclu') || widget.doacao.agendamentoAtivo?.status == 'concluido') && widget.doacao.agendamentoAtivo != null && !_isActionLoading)
              Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.containerHigh.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('Logística de Retirada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
                            child: const Text('CONCLUÍDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Horário em que a doação foi concluída:',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.doacao.agendamentoAtivo!.dataHora != null ? _formatDateTime(widget.doacao.agendamentoAtivo!.dataHora!) : 'Data não disponível',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (_receptorNome != null) ...[
                        const SizedBox(height: 8),
                        Text('Recebido por: $_receptorNome', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ),

            if (statusNormalizado == 'disponivel' && possuiInteressados && !_isActionLoading)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryContainer,
                      side: const BorderSide(color: AppColors.primaryContainer),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.people_outline, size: 18),
                    label: const Text('Ver Interessados e Escolher'),
                    onPressed: _abrirModalInteressados,
                  ),
                ),
              ),

            if (statusNormalizado == 'reservado' && widget.doacao.agendamentoAtivo != null && !_isActionLoading)
              Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.containerHigh.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primaryContainer),
                          const SizedBox(width: 8),
                          const Text('Painel de Alinhamento Logístico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text(
                            widget.doacao.agendamentoAtivo!.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.bold, 
                              color: widget.doacao.agendamentoAtivo!.status == 'confirmado' ? Colors.green.shade700 : Colors.orange.shade700
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.doacao.agendamentoAtivo!.dataHora != null
                            ? 'Horário Proposto: ${_formatDateTime(widget.doacao.agendamentoAtivo!.dataHora!)}'
                            : 'Aguardando primeira sugestão de horário de retirada.',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (widget.doacao.agendamentoAtivo!.status == 'pendente') ...[
                            Expanded(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: AppColors.onSurface),
                                icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                                label: const Text('Propor Horário', style: TextStyle(fontSize: 12)),
                                onPressed: _handleProporDisponibilidade,
                              ),
                            ),
                            if (widget.doacao.agendamentoAtivo!.dataHora != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryContainer,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Confirmar Horário', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _executarAcaoLogistica(
                                    () => AgendamentoService.instance.confirmarAgendamento(widget.doacao.id),
                                    'Horário confirmado com sucesso!',
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (widget.doacao.agendamentoAtivo!.status == 'confirmado')
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.done_all, size: 18),
                                label: const Text('Confirmar Entrega Física (Item Doado)'),
                                onPressed: () => _executarAcaoLogistica(
                                  () => AgendamentoService.instance.concluirEntrega(widget.doacao.id),
                                  'Entrega concluída com sucesso! Obrigado por doar.',
                                ),
                              ),
                            ),
                        ],
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