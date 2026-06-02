import 'package:flutter/material.dart';
import 'package:doaai/auth/services/token_storage.dart';
import 'package:doaai/auth/services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  late Future<List<dynamic>> _usuariosFuture;

  final int doacoesConcluidas = 890; // Fixo por enquanto

  List<Map<String, dynamic>> doacoesAtivas = [
    {"item": "Cadeira de Rodas", "doador": "Carlos", "data": "10/10/2023"},
    {"item": "Roupas de Frio", "doador": "Fernanda", "data": "09/10/2023"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _validarAcessoAdmin();

    _usuariosFuture = AdminService.instance.buscarUsuarios();
  }

  Future<void> _validarAcessoAdmin() async {
    bool isAdmin = await TokenStorage.instance.getIsAdmin();

    if (!isAdmin) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acesso negado.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fazerLogout() {
    TokenStorage.instance.clearTokens();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D7A1F)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'DoaAi - Backoffice',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2D7A1F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sair',
            onPressed: _fazerLogout,
          ),
        ],
      ),
      drawer: _buildMenuLateral(),
      body: Column(
        children: [
          _buildIndicadoresGlobais(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildListaUsuarios(), _buildListaDoacoes()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuLateral() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2D7A1F)),
            accountName: Text(
              "Administrador Sistema",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text("admin@doaai.com.br"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                color: Color(0xFF2D7A1F),
                size: 40,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF2D7A1F)),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.report_problem),
            title: const Text('Denúncias de Doações'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair do Sistema',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _fazerLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadoresGlobais() {
    return FutureBuilder<List<dynamic>>(
      future: _usuariosFuture,
      builder: (context, snapshot) {
        
        String totalReal = '...'; 
        
        if (snapshot.hasData) {
          totalReal = snapshot.data!.length.toString();
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF2D7A1F),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CardIndicador(
                  titulo: 'Total de Usuários',
                  valor: totalReal,
                  icone: Icons.people_alt_rounded,
                  corIcone: const Color(0xFF2D7A1F),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardIndicador(
                  titulo: 'Doações Concluídas',
                  valor: doacoesConcluidas.toString(),
                  icone: Icons.check_circle_rounded,
                  corIcone: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2D7A1F),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2D7A1F),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.manage_accounts), text: 'Usuários'),
          Tab(icon: Icon(Icons.volunteer_activism), text: 'Doações Ativas'),
        ],
      ),
    );
  }

  Widget _buildListaUsuarios() {
    return FutureBuilder<List<dynamic>>(
      future: _usuariosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D7A1F)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar usuários.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum usuário cadastrado no sistema.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final usuariosCadastrados = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: usuariosCadastrados.length,
          itemBuilder: (context, index) {
            final usuario = usuariosCadastrados[index];
            final String nome = usuario['nome'] ?? 'Sem nome';
            final String email = usuario['email'] ?? 'Sem e-mail';
            
            final int rawId = usuario['id'] ?? 0; 
            final String idUsuario = rawId.toString();
            
            final bool isBloqueado = usuario['bloqueado'] == true;
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBloqueado ? Colors.red[100] : Colors.blue[100],
                  child: Icon(
                    isBloqueado ? Icons.lock : Icons.person,
                    color: isBloqueado ? Colors.red : Colors.blue,
                  ),
                ),
                title: Text(
                  nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('$email  •  ID: $idUsuario'),
                trailing: IconButton(
                  icon: Icon(
                    isBloqueado ? Icons.lock_open : Icons.block,
                    color: isBloqueado ? Colors.green : Colors.red,
                  ),
                  tooltip: isBloqueado ? 'Desbloquear' : 'Bloquear',
                  onPressed: () async {
                    try {
                      await AdminService.instance.atualizarUsuario(
                        id: rawId,
                        bloqueado: !isBloqueado,
                      );
                      setState(() {
                        _usuariosFuture = AdminService.instance.buscarUsuarios();
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isBloqueado ? 'Usuário desbloqueado!' : 'Usuário bloqueado!'),
                          backgroundColor: isBloqueado ? Colors.green : Colors.red,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListaDoacoes() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: doacoesAtivas.length,
      itemBuilder: (context, index) {
        final doacao = doacoesAtivas[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Colors.orange,
              ),
            ),
            title: Text(
              doacao["item"],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Doador: ${doacao["doador"]}\nPostado em: ${doacao["data"]}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
              tooltip: 'Ver detalhes',
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}

class _CardIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color corIcone;

  const _CardIndicador({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.corIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: corIcone, size: 32),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}