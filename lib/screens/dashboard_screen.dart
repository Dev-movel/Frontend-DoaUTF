import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/usuario_service.dart';
import '../widgets/main_app_bar.dart';
import 'agendamento_screen.dart'; 
import '../models/usuario.dart';
import '../models/doacao.dart';
import '../widgets/dashboard/status_filter_row.dart';

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
    final pedidosAtivos = _minhasDoacoes.where((doacao) => _isOrderStatus(doacao.status)).toList();
    final currentUserId = _usuario?.id;
    final pedidosConcluidos = _meusAgendamentos.where((a) {
      if (currentUserId == null) return false;
      final status = (a['status'] ?? '').toString().toLowerCase();
      final rawReceptorId = a['receptor_id'] ?? a['receptorId'];
      final receptorId = rawReceptorId is int ? rawReceptorId : int.tryParse(rawReceptorId?.toString() ?? '');
      return status == 'concluido' && receptorId == currentUserId;
    }).toList();
    final atividadesRecentes = pedidosConcluidos.reversed.take(4).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/dashboard'),

      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
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
                final cols = constraints.maxWidth > 800 ? 3 : 1;
                final totalSpacing = 24.0 * (cols - 1);
                final cardWidth = (constraints.maxWidth - totalSpacing) / cols;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _buildStatCard('$_totalItensDoadosContador', 'ITENS DOADOS', Icons.volunteer_activism, AppColors.primaryContainer, Colors.white, cardWidth),
                    _buildStatCard('$_itensRecebidos', 'ITENS RECEBIDOS', Icons.inventory_2_outlined, Colors.blue, Colors.white, cardWidth),
                    // Pontuação de sustentabilidade: mantida sempre em 0 por decisão do time
                    _buildStatCard('0', 'PONTUAÇÃO DE SUSTENTABILIDADE', Icons.eco_outlined, AppColors.surface, AppColors.onSurface, cardWidth),
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
                        'Minhas Doações Atuais',
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
                        ...(_expandedDoacoes ? _minhasDoacoes : _minhasDoacoes.take(_itemsPerPage)).map((doacao) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDonationCard(doacao),
                        )),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        'Meus Pedidos',
                        onViewAll: () => setState(() => _expandedPedidos = !_expandedPedidos),
                        isExpanded: _expandedPedidos,
                        itemCount: pedidosConcluidos.length,
                      ),
                      const SizedBox(height: 16),
                      if (pedidosConcluidos.isEmpty)
                        const Text('Nenhum pedido ativo no momento.', style: TextStyle(color: AppColors.outline))
                      else
                        ...(_expandedPedidos ? pedidosConcluidos : pedidosConcluidos.take(_itemsPerPage)).map((ag) {
                          final dynamic rawId = ag['item_id'] ?? ag['id'];
                          final int? itemId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
                          final foto = itemId != null ? _receivedFotos[itemId] : null;
                          return _buildOrderItem(
                            ag['item_titulo'] ?? 'Item',
                            'Status: ${ag['status']}',
                            (ag['status'] ?? '').toUpperCase(),
                            _getStatusColor(ag['status'] ?? ''),
                            fotoUrl: foto,
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
                          _buildSidebarLink(Icons.map_outlined, 'Abrir Mapa de Impacto'),
                          _buildSidebarLink(
                            Icons.settings_outlined, 
                            'Configurações de Perfil',
                            onTap: () => Navigator.pushNamed(context, '/profile'),
                        ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSidebarCard('Atividade Recente', [
                          if (atividadesRecentes.isEmpty) ...[
                            const Text('Nenhuma atividade recente disponível.', style: TextStyle(color: AppColors.outline)),
                          ] else ...atividadesRecentes.map((ag) => _buildActivityItem(
                            'Atualização de doação',
                            'Seu pedido "${ag['item_titulo']}" foi ${ag['status'].toString().toLowerCase()}',
                            'RECENTE',
                            _getStatusColor(ag['status'] ?? ''),
                          )),
                        ]),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color bg, Color textCol, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textCol.withOpacity(0.8)),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textCol)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textCol.withOpacity(0.7))),
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

    if (normalized.contains('doado') || normalized.contains('entreg') || normalized.contains('conclu')) {
      return Colors.green.shade100; // Doado / Entregue / Concluído
    }
    if (normalized.contains('reserv') || normalized.contains('reservado')) {
      return Colors.orange.shade100; // Reservado
    }
    if (normalized.contains('dispon') || normalized.contains('disponivel') || normalized.contains('disponível') || normalized.contains('anunciado')) {
      return Colors.blue.shade100; // Disponível / Anunciado
    }

    if (normalized.contains('aguardando') || normalized.contains('pendente')) {
      return Colors.orange.shade100;
    }
    if (normalized.contains('aprovado')) {
      return Colors.green.shade100;
    }

    return AppColors.containerHigh;
  }

  Color _getStatusTextColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized.contains('doado') || normalized.contains('entreg') || normalized.contains('conclu') || normalized.contains('aprovado')) {
      return Colors.green.shade800;
    }
    if (normalized.contains('reserv') || normalized.contains('reservado') || normalized.contains('aguardando') || normalized.contains('pendente')) {
      return Colors.orange.shade800;
    }
    if (normalized.contains('dispon') || normalized.contains('disponivel') || normalized.contains('disponível') || normalized.contains('anunciado')) {
      return Colors.blue.shade800;
    }

    return AppColors.onSurface;
  }

  int _countReceivedDonations() {
    return _minhasDoacoes.where((doacao) {
      final status = doacao.status.toLowerCase();
      return status.contains('receb') || status.contains('entreg') || status.contains('conclu') || status.contains('finaliz');
    }).length;
  }

  int _countActiveDonations() {
    return _minhasDoacoes.where((doacao) {
      final status = doacao.status.toLowerCase();
      return status.contains('pendente') || status.contains('aguardando') || status.contains('anunciado') || status.contains('aprovado');
    }).length;
  }

  bool _isOrderStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('pendente') || normalized.contains('aguardando') || normalized.contains('anunciado') || normalized.contains('aprovado');
  }

  Widget _buildDonationCard(Doacao doacao) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: doacao.fotoUrl != null && doacao.fotoUrl!.isNotEmpty
                ? Image.network(
                    doacao.fotoUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.containerHigh,
                      child: const Icon(Icons.volunteer_activism, color: Colors.white),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.containerHigh,
                    child: const Icon(Icons.volunteer_activism, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _getStatusColor(doacao.status), borderRadius: BorderRadius.circular(4)),
                child: Text(doacao.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text(doacao.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Status atual: ${doacao.status}', style: const TextStyle(fontSize: 12, color: AppColors.outline)),
              const SizedBox(height: 8),
              // Pontuação de sustentabilidade: manter sempre 0 por decisão de implementação futura
              Row(
                children: const [
                  Icon(Icons.eco_outlined, size: 14, color: AppColors.outline),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Pontuação de sustentabilidade: 0',
                      style: TextStyle(fontSize: 12, color: AppColors.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildOrderItem(String title, String info, String status, Color statusCol, {String? fotoUrl}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: fotoUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fotoUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => CircleAvatar(backgroundColor: AppColors.containerHigh, child: const Icon(Icons.shopping_bag_outlined)),
            ),
          )
        : CircleAvatar(backgroundColor: AppColors.containerHigh, child: const Icon(Icons.shopping_bag_outlined)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(info),
      trailing: Text(status, style: TextStyle(color: _getStatusTextColor(status), fontWeight: FontWeight.bold)),
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