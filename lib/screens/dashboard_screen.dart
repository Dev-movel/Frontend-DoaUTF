import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/usuario_service.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/donation_card.dart';
import '../models/usuario.dart';
import '../models/doacao.dart';
import '../widgets/dashboard/status_filter_row.dart';
import '../widgets/dashboard/agendamento_section.dart';
import '../widgets/dashboard/gerenciador_solicitacoes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Usuario? _usuario;
  String _nomeUsuario = 'Usuário';
  List<Doacao> _minhasDoacoes = [];
  int _itensRecebidos = 0;
  List<dynamic> _meusAgendamentos = [];
  Map<int, String?> _receivedFotos = {};
  bool _expandedDoacoes = false;
  bool _expandedPedidos = false;
  static const int _itemsPerPage = 4;
  String _statusSelecionado = 'Todos';
  final List<String> _filtrosStatus = ['Todos', 'Disponíveis', 'Reservados', 'Doados'];
  bool _isLoadingDoacoes = false;
  int _totalItensDoadosContador = 0;

  int _safelyParseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

  String? _mapearStatusParaApi(String filtro) {
    switch (filtro) {
      case 'Disponíveis': return 'disponivel';
      case 'Reservados': return 'reservado';
      case 'Doados': return 'doado';
      default: return null;
    }
  }

  Future<void> _filtrarDoacoes() async {
    setState(() => _isLoadingDoacoes = true);
    try {
      final statusApi = _mapearStatusParaApi(_statusSelecionado);
      final donations = await UsuarioService.instance.getMyDonations(status: statusApi);
      setState(() {
        _minhasDoacoes = donations;
      });
    } catch (e) {
      debugPrint('Erro ao filtrar doações: $e');
    } finally {
      setState(() => _isLoadingDoacoes = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _minhasDoacoes = [];
        _itensRecebidos = 0;
        _meusAgendamentos = [];
        _receivedFotos = {};
      });

      final user = await UsuarioService.instance.getMe();
      final donations = await UsuarioService.instance.getMyDonations(
        status: _mapearStatusParaApi(_statusSelecionado),
      );
      final received = await UsuarioService.instance.getReceivedDonations();
      final agendamentos = await UsuarioService.instance.getMyAgendamentos();

      final Map<int, String?> fotoMap = {};
      for (final d in received) {
        fotoMap[d.id] = d.fotoUrl;
      }

      setState(() {
        _usuario = user;
        _nomeUsuario = user.nome.isNotEmpty ? user.nome : 'Usuário';
        _minhasDoacoes = donations;
        
        if (_statusSelecionado == 'Todos') {
          _totalItensDoadosContador = donations.length;
        }

        _itensRecebidos = received.length;
        _meusAgendamentos = agendamentos;
        _receivedFotos = fotoMap;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dashboard: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _usuario?.id;
    final pedidosConcluidos = _meusAgendamentos.where((a) {
      if (currentUserId == null) return false;
      final receptorId = _safelyParseInt(a['receptor_id'] ?? a['receptorId']);
      final doadorId = _safelyParseInt(a['doador_id'] ?? a['doadorId']);

      return receptorId == currentUserId || doadorId == currentUserId;
    }).toList();

    final pedidosRecebidos = pedidosConcluidos.where((a) {
      if (currentUserId == null) return false;
      final receptorId = _safelyParseInt(a['receptor_id'] ?? a['receptorId']);
      return receptorId == currentUserId;
    }).toList();

    final atividadesRecentes = _meusAgendamentos.take(4).toList();
    final isMobile = MediaQuery.of(context).size.width < 600;

return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/dashboard'),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _carregarDados,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _usuario?.nome.isNotEmpty == true ? _usuario!.nome[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bem-vindo de volta, $_nomeUsuario.',
                              style: TextStyle(fontSize: isMobile ? 20 : 32, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sua jornada de sustentabilidade está fazendo uma diferença real na comunidade.',
                              style: TextStyle(fontSize: isMobile ? 13 : 16, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 1000 ? 2 : 1;
                      final spacing = constraints.maxWidth > 600 ? 24.0 : 16.0;
                      final totalSpacing = spacing * (cols - 1);
                      final cardWidth = min((constraints.maxWidth - totalSpacing) / cols, 460.0);
                      return Wrap(
                        alignment: WrapAlignment.start,
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          _buildStatCard('$_totalItensDoadosContador', 'ITENS DOADOS', Icons.volunteer_activism, AppColors.primaryContainer, Colors.white, cardWidth, isMobile),
                          _buildStatCard('$_itensRecebidos', 'ITENS RECEBIDOS', Icons.inventory_2_outlined, Colors.blue, Colors.white, cardWidth, isMobile),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 48),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSectionHeader(
                              'Minhas Doações',
                              onViewAll: () => setState(() => _expandedDoacoes = !_expandedDoacoes),
                              isExpanded: _expandedDoacoes,
                              itemCount: _minhasDoacoes.length,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: StatusFilterRow(
                                filtros: _filtrosStatus,
                                statusSelecionado: _statusSelecionado,
                                onStatusChanged: (novoStatus) {
                                  setState(() {
                                    _statusSelecionado = novoStatus;
                                  });
                                  _filtrarDoacoes(); 
                                },
                              ),
                            ),

                            if (_isLoadingDoacoes)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_minhasDoacoes.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.outline.withOpacity(0.5)),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Você não possui itens com este status no momento.',
                                        style: TextStyle(color: AppColors.outline, fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...(_expandedDoacoes ? _minhasDoacoes : _minhasDoacoes.take(_itemsPerPage)).map((doacao) {
                                final statusStr = doacao.status.toLowerCase();
                                final isDoado = statusStr.contains('doado') || statusStr.contains('conclu');
                                final isReservado = statusStr.contains('reserv');

                                final match = _meusAgendamentos.where((ag) => _safelyParseInt(ag['item_id']) == doacao.id);
                                final agendamento = match.isNotEmpty ? match.first : null;

                                String? localEntrega = agendamento?['localizacao'];
                                String? receptorNome = agendamento?['receptor_nome'];

                                String infoTexto;
                                if (isDoado) {
                                  infoTexto = 'Doado para: ${receptorNome ?? "Interessado"}\nLocal: ${localEntrega ?? "Não informado"}';
                                } else if (isReservado) {
                                  infoTexto = 'Reservado para: ${receptorNome ?? "Interessado"}\nLocal: ${localEntrega ?? "A combinar"}';
                                } else {
                                  infoTexto = 'Disponível para doação\nLocal: ${localEntrega ?? "A combinar"}';
                                }

                                return _buildOrderItemInterative(
                                  doacao.titulo,
                                  infoTexto,
                                  doacao.status.toUpperCase(),
                                  _getStatusColor(statusStr),
                                  fotoUrl: doacao.fotoUrl,
                                  itemId: doacao.id,
                                  usuarioId: _usuario?.id ?? 0,
                                  localEntrega: localEntrega,
                                  parceiroNome: receptorNome,
                                  souODoador: true,
                                  onRefresh: _carregarDados,
                                  onTapOverride: statusStr.contains('dispon') ? () => _abrirSolicitacoesDoItem(
                                    doacao.id,
                                    doacao.titulo,
                                  ) : null,
                                );
                              }),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              'Meus Pedidos',
                              onViewAll: () => setState(() => _expandedPedidos = !_expandedPedidos),
                              isExpanded: _expandedPedidos,
                              itemCount: pedidosRecebidos.length,
                            ),
                            const SizedBox(height: 16),
                            if (pedidosRecebidos.isEmpty)
                              const Text('Nenhum pedido ativo no momento.', style: TextStyle(color: AppColors.outline))
                            else
                              ...(_expandedPedidos ? pedidosRecebidos : pedidosRecebidos.take(_itemsPerPage)).map((ag) {
                                final dynamic rawId = ag['item_id'] ?? ag['id'];
                                final int? itemId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                                final foto = itemId != null ? _receivedFotos[itemId] : null;

                                final int doadorId = ag['doador_id'] is int
                                  ? ag['doador_id'] as int
                                  : int.tryParse(ag['doador_id']?.toString() ?? '') ?? 0;
                                final bool souODoador = currentUserId == doadorId;
                                final String nomeOutraPessoa = souODoador 
                                    ? (ag['receptor_nome'] ?? 'Interessado')
                                    : (ag['doador_nome'] ?? 'Doador');
                                final String localEntrega = ag['localizacao'] ?? 'Não informado';
                                final String statusStr = (ag['status'] ?? '').toString().toLowerCase();

                                String infoTexto;
                                if (statusStr == 'concluido') {
                                  final String vinculo = souODoador ? 'Doado para' : 'Recebido de';
                                  infoTexto = '$vinculo: $nomeOutraPessoa\nLocal: $localEntrega';
                                } else {
                                  infoTexto = 'Doador: $nomeOutraPessoa\nLocal: $localEntrega';
                                }

                                return _buildOrderItemInterative(
                                  ag['item_titulo'] ?? 'Item',
                                  infoTexto,
                                  statusStr.toUpperCase(),
                                  _getStatusColor(statusStr),
                                  fotoUrl: foto,
                                  itemId: itemId ?? 0,
                                  usuarioId: _usuario?.id ?? 0,
                                  localEntrega: localEntrega,
                                  parceiroNome: nomeOutraPessoa,
                                  souODoador: souODoador,
                                  onRefresh: _carregarDados,
                                );
                              }),
                          ],
                        ),
                      ),
                      
                      if (MediaQuery.of(context).size.width > 1000)
                        const SizedBox(width: 48),

                      if (MediaQuery.of(context).size.width > 1000)
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildSidebarCard('Links Rápidos', [
                                _buildSidebarLink(
                                  Icons.map_outlined, 
                                  'Abrir Mapa de Impacto'),
                                _buildSidebarLink(
                                  Icons.settings_outlined, 
                                  'Configurações de Perfil',
                                  onTap: () => Navigator.pushNamed(context, '/profile'),
                                ),
                              ]),
                              const SizedBox(height: 24),
                              _buildSidebarCard('Atividade Recente', [
                                  if (atividadesRecentes.isEmpty) ...[
                                    const Text('Nenhuma atividade recente disponível.', 
                                    style: TextStyle(color: AppColors.outline)),
                                  ] else ...atividadesRecentes.map((ag) {
                                  
                                    final int doadorId = ag['doador_id'] is int
                                      ? ag['doador_id'] as int
                                      : int.tryParse(ag['doador_id']?.toString() ?? '') ?? 0;

                                    final bool souODoador = currentUserId == doadorId;
                                    final String nomeOutraPessoa = souODoador 
                                        ? (ag['receptor_nome'] ?? 'Interessado')
                                        : (ag['doador_nome'] ?? 'Doador');
                                    final String localEntrega = ag['localizacao'] ?? 'Não informado';
                                    final String statusStr = (ag['status'] ?? '').toString().toLowerCase();

                                    String descTexto;
                                    if (statusStr == 'concluido' || statusStr == 'doado') {
                                      final String vinculo = souODoador ? 'Doado para' : 'Recebido de';
                                      descTexto = '$vinculo: $nomeOutraPessoa\nLocal: $localEntrega';
                                    } else {
                                      final String vinculo = souODoador ? 'Reservado para' : 'Doador';
                                      descTexto = '$vinculo: $nomeOutraPessoa\nLocal: $localEntrega';
                                    }

                                    String tempoStr = 'RECENTE';
                                    if (ag['data_hora'] != null) {
                                      try {
                                        final dt = DateTime.parse(ag['data_hora']).toLocal();
                                        tempoStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                      } catch (_) {}
                                    }

                                    return _buildActivityItem(
                                      ag['item_titulo'] ?? 'Atualização de doação',
                                      descTexto,
                                      tempoStr,
                                      _getStatusColor(statusStr),
                                    );
                                  }),
                              ]),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color bg, Color textCol, double width, bool isMobile) {
    final padding = isMobile ? 16.0 : 18.0;
    final spacing = isMobile ? 12.0 : 14.0;
    final valueSize = isMobile ? 36.0 : 42.0;
    final labelSize = isMobile ? 11.0 : 12.0;

    return Container(
      width: width,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textCol.withOpacity(0.8), size: valueSize * 0.55),
          SizedBox(height: spacing),
          Text(value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.bold, color: textCol)),
          Text(label, style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w500, color: textCol.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll, bool isExpanded = false, int itemCount = 0}) {
    final hasMore = itemCount > _itemsPerPage;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ),
        if (hasMore)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              isExpanded ? 'Mostrar Menos' : 'Ver Tudo',
              style: const TextStyle(color: AppColors.primaryContainer),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('doado') || normalized.contains('entreg') || normalized.contains('confirmado')) return Colors.green.shade100;
    if (normalized.contains('reserv') || normalized.contains('reservado') || normalized.contains('pendente')) return Colors.orange.shade100;
    if (normalized.contains('dispon')) return Colors.blue.shade100;
    return AppColors.containerHigh;
  }

  Color _getStatusTextColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('doado') || normalized.contains('entreg') || normalized.contains('confirmado')) return Colors.green.shade800;
    if (normalized.contains('reserv') || normalized.contains('reservado') || normalized.contains('pendente')) return Colors.orange.shade800;
    if (normalized.contains('dispon')) return AppColors.primaryContainer;
    return AppColors.onSurface;
  }

  Widget _buildOrderItemInterative(String title, String info, String status, Color statusCol, {String? fotoUrl, required int itemId, required int usuarioId, String? localEntrega, String? parceiroNome, bool souODoador = false, required VoidCallback onRefresh, VoidCallback? onTapOverride,}) {
    final bool isDisponivel = status.toLowerCase().contains('disponiv');
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTapOverride ?? () => _abrirAgendamentoDoReceptor(
          itemId, 
          usuarioId, 
          title, 
          fotoUrl,
          localEntrega: localEntrega,
          parceiroNome: parceiroNome,
          souODoador: souODoador,
          status: status,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              fotoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fotoUrl, width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => CircleAvatar(backgroundColor: AppColors.containerHigh, child: const Icon(Icons.shopping_bag_outlined)),
                    ),
                  )
                : CircleAvatar(backgroundColor: AppColors.containerHigh, child: const Icon(Icons.shopping_bag_outlined), radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(info, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusCol,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(color: _getStatusTextColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirAgendamentoDoReceptor(int itemId, int usuarioId, String itemTitle, String? fotoUrl, {String? localEntrega, String? parceiroNome, bool souODoador = false, String? status,}) async {
    final String parceiroLabel;
    final statusClean = status?.toLowerCase() ?? '';

    if (souODoador) {
      parceiroLabel = statusClean.contains('doado') ? 'Doado para' : 'Reservado para';
    } else {
      parceiroLabel = statusClean.contains('doado') ? 'Recebido de' : 'Doador';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Agendamento: $itemTitle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (parceiroNome != null) ...[
                  Text('$parceiroLabel: $parceiroNome', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                ],
                if (localEntrega != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Local: $localEntrega', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                AgendamentoSection(
                  itemId: _safelyParseInt(itemId),
                  usuarioId: _safelyParseInt(usuarioId),
                  onRefresh: _carregarDados,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSolicitacoesDoItem(int itemId, String itemTitle) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Interessados: $itemTitle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ModalInteressadosBottomSheet(
                  itemId: itemId,
                  onSolicitacaoAceita: _carregarDados,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.containerHigh.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildSidebarLink(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.primaryContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          const Icon(Icons.chevron_right, size: 16),
        ]),
      ),
    );
  }

  Widget _buildActivityItem(String title, String desc, String time, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: dotColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
          Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        ])),
      ]),
    );
  }
}