import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/usuario_service.dart';
import '../models/usuario.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final user = await UsuarioService.instance.getMe();
      setState(() {
        _usuario = user;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('DoaUTF', 
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Home', style: TextStyle(color: AppColors.onSurface))),
          TextButton(onPressed: () {}, child: const Text('Mapa', style: TextStyle(color: AppColors.onSurface))),
          TextButton(onPressed: () {}, child: const Text('Doar', style: TextStyle(color: AppColors.onSurface))),
          TextButton(onPressed: () {}, child: const Text('Dashboard', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'), 
            child: const Text('Perfil', style: TextStyle(color: AppColors.onSurface))
          ),
          const SizedBox(width: 20),
          const Icon(Icons.notifications_none, color: AppColors.onSurface),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 15, 
              backgroundColor: AppColors.primary,
              child: Text(
                _usuario != null ? _usuario!.nome[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo de volta, ${_usuario?.nome ?? "Usuário"}.', 
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
                    _buildStatCard('24', 'ITENS DOADOS', Icons.volunteer_activism, AppColors.primaryContainer, Colors.white, cardWidth),
                    _buildStatCard('12', 'ITENS RECEBIDOS', Icons.inventory_2_outlined, Colors.blue, Colors.white, cardWidth),
                    _buildStatCard('942', 'PONTUAÇÃO DE SUSTENTABILIDADE', Icons.eco_outlined, AppColors.surface, AppColors.onSurface, cardWidth),
                  ],
                );
              }
            ),
            const SizedBox(height: 48),

            // Área Principal e Sidebar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna da Esquerda: Doações e Pedidos
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSectionHeader('Minhas Doações Atuais'),
                      const SizedBox(height: 16),
                      _buildDonationCard('Relógio Seiko Vintage', 'Retirada agendada para amanhã, 14h', 'AGUARDANDO RETIRADA', Colors.orange.shade100),
                      const SizedBox(height: 12),
                      _buildDonationCard('Tênis Esportivo Vermelho', '2 pedidos ativos pendentes', 'ANUNCIADO', Colors.green.shade100),
                      
                      const SizedBox(height: 32),
                      _buildSectionHeader('Meus Pedidos'),
                      const SizedBox(height: 16),
                      _buildOrderItem('Cafeteira Prensa Francesa', 'Solicitado de Sarah J. • a 2km', 'Aprovado', Colors.green),
                      const Divider(),
                      _buildOrderItem('Coleção de Literatura Clássica', 'Solicitado de Biblioteca Verde • a 5km', 'Pendente', Colors.grey),
                    ],
                  ),
                ),
                
                const SizedBox(width: 48),

                // Coluna da Direita (Sidebar): Links e Atividade
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
                          _buildActivityItem('Avaliação Concluída', 'Sua doação de "Luvas de Forno" foi verificada', 'HÁ 2 HORAS', Colors.green),
                          _buildActivityItem('Ganhou o Selo Guardião da Terra', 'Completou 10 doações bem-sucedidas este mês', 'ONTEM', Colors.blue),
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
          Icon(icon, color: textCol.withOpacity(0.8)),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textCol)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textCol.withOpacity(0.7))),
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

  Widget _buildDonationCard(String title, String subtitle, String tag, Color tagBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.containerHigh, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
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
          Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.outlineVariant)),
        ])),
      ]),
    );
  }
}