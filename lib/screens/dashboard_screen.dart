import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/usuario_service.dart';
import '../widgets/main_app_bar.dart';
import 'agendamento_screen.dart'; 
import '../models/usuario.dart';
import '../models/doacao.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Usuario? _usuario;
  List<Doacao> _minhasDoacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final user = await UsuarioService.instance.getMe();
      final donations = await UsuarioService.instance.getMyDonations();
      setState(() {
        _usuario = user;
        _minhasDoacoes = donations;
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

  void _abrirInjetorDeTeste() {
    final TextEditingController itemController = TextEditingController();
    final TextEditingController userController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.bug_report, color: Colors.red),
            SizedBox(width: 8),
            Text('Injetor de Teste'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira os IDs para abrir a tela de agendamento diretamente:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(
                labelText: 'ID do Item (item_id)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: 'Seu ID de Usuário (usuarioIdAtual)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final itemId = int.tryParse(itemController.text);
              final usuarioId = int.tryParse(userController.text);

              if (itemId == null || usuarioId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, insira IDs válidos!'), backgroundColor: Colors.orange),
                );
                return;
              }

              Navigator.pop(context); 
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgendamentoScreen(
                    itemId: itemId,
                    usuarioIdAtual: usuarioId,
                  ),
                ),
              );
            },
            child: const Text('Abrir Tela', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedidosAtivos = _minhasDoacoes.where((doacao) => _isOrderStatus(doacao.status)).toList();
    final atividadesRecentes = _minhasDoacoes.take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/dashboard'),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: _abrirInjetorDeTeste,
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
      
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo de volta, $_nomeUsuario.',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.onSurface)
                ),
                const Text(
                  'Sua jornada de sustentabilidade está fazendo uma diferença real na comunidade.',
                  style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)
                ),
                const SizedBox(height: 32),

            // Layout Responsivo (Estatísticas)
            LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = (constraints.maxWidth - 48) / (constraints.maxWidth > 800 ? 3 : 1);
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _buildStatCard('${_minhasDoacoes.length}', 'ITENS DOADOS', Icons.volunteer_activism, AppColors.primaryContainer, Colors.white, cardWidth),
                    _buildStatCard('${_countReceivedDonations()}', 'ITENS RECEBIDOS', Icons.inventory_2_outlined, Colors.blue, Colors.white, cardWidth),
                    _buildStatCard('${_countActiveDonations()}', 'DOAÇÕES ATIVAS', Icons.eco_outlined, AppColors.surface, AppColors.onSurface, cardWidth),
                  ],
                );
              }
            ),
            const SizedBox(height: 48),

            // Área Principal e Sidebar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSectionHeader('Minhas Doações Atuais'),
                      const SizedBox(height: 16),
                      if (_minhasDoacoes.isEmpty)
                        const Text('Ainda não há doações ativas.', style: TextStyle(color: AppColors.outline))
                      else
                        ..._minhasDoacoes.map((doacao) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDonationCard(doacao),
                        )),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Meus Pedidos'),
                      const SizedBox(height: 16),
                      if (pedidosAtivos.isEmpty)
                        const Text('Nenhum pedido ativo no momento.', style: TextStyle(color: AppColors.outline))
                      else
                        ...pedidosAtivos.take(2).map((pedido) => _buildOrderItem(
                          pedido.titulo,
                          'Status: ${pedido.status}',
                          pedido.status.toUpperCase(),
                          _getStatusColor(pedido.status),
                        )),
                    ],
                  ),
                ),
                
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
                          ] else ...atividadesRecentes.map((doacao) => _buildActivityItem(
                            'Atualização de doação',
                            'Sua doação "${doacao.titulo}" está ${doacao.status.toLowerCase()}',
                            'RECENTE',
                            _getStatusColor(doacao.status),
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

  // --- Widgets Auxiliares ---

  Widget _buildStatCard(String value, String label, IconData icon, Color bg, Color textCol, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textCol.withValues(alpha: 0.8)),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textCol)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textCol.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('Ver Tudo', style: TextStyle(color: AppColors.primaryContainer))),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('aguardando') || normalized.contains('pendente')) {
      return Colors.orange.shade100;
    }
    if (normalized.contains('anunciado') || normalized.contains('aprovado') || normalized.contains('concluído') || normalized.contains('concluido') || normalized.contains('recebido') || normalized.contains('entreg')) {
      return Colors.green.shade100;
    }
    return AppColors.containerHigh;
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
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildOrderItem(String title, String info, String status, Color statusCol) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: AppColors.containerHigh, child: const Icon(Icons.shopping_bag_outlined)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(info),
      trailing: Text(status, style: TextStyle(color: statusCol, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSidebarCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.containerHigh.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
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
          Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.outlineVariant)),
        ])),
      ]),
    );
  }
}