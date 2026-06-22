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

  // Controlador e string para a barra de pesquisa de usuários
  final TextEditingController _searchController = TextEditingController();
  String _filtroNome = '';

  // Futures que vão buscar os dados reais da API
  late Future<List<dynamic>> _usuariosFuture;
  late Future<List<dynamic>> _doacoesAtivasFuture;
  // Future dedicado para buscar as denúncias de posts do backend
  late Future<List<dynamic>> _postsDenunciadosFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _validarAcessoAdmin();
    _carregarDados();

    // Ouvinte para atualizar a tela conforme o admin digita na pesquisa
    _searchController.addListener(() {
      setState(() {
        _filtroNome = _searchController.text.toLowerCase();
      });
    });
  }

  void _carregarDados() {
    setState(() {
      _usuariosFuture = AdminService.instance.buscarUsuarios();
      _doacoesAtivasFuture = AdminService.instance.buscarDoacoesAtivas();
      _postsDenunciadosFuture = AdminService.instance.buscarPostsDenunciados();
    });
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
    _searchController.dispose();
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Dados',
            onPressed: _carregarDados,
          ),
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
              children: [
                _buildListaUsuarios(), 
                _buildListaDoacoes(),
                _buildListaPostsDenunciados(), 
              ],
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
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.amber),
            title: const Text('Denúncias de Doações'),
            onTap: () {
              Navigator.pop(context); 
              _tabController.animateTo(2); 
            },
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2D7A1F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: FutureBuilder<List<dynamic>>(
        future: _usuariosFuture,
        builder: (context, snapshot) {
          String totalUsuarios = '...';
          String totalBloqueados = '...';

          if (snapshot.hasData) {
            final lista = snapshot.data!;
            totalUsuarios = lista.length.toString();
            int bloqueadosCount = lista.where((u) => u['bloqueado'] == true).length;
            totalBloqueados = bloqueadosCount.toString();
          }

          return Row(
            children: [
              Expanded(
                child: _CardIndicador(
                  titulo: 'Total de Usuários',
                  valor: totalUsuarios,
                  icone: Icons.people_alt_rounded,
                  corIcone: const Color(0xFF2D7A1F),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardIndicador(
                  titulo: 'Usuários Bloqueados',
                  valor: totalBloqueados,
                  icone: Icons.block_flipped,
                  corIcone: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
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
          Tab(icon: Icon(Icons.report_gmailerrorred_rounded), text: 'Denúncias'),
        ],
      ),
    );
  }

  Widget _buildListaUsuarios() {
    return FutureBuilder<List<dynamic>>(
      future: _usuariosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D7A1F)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar usuários.\n${snapshot.error}',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Nenhum usuário cadastrado no sistema.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        final usuariosCadastrados = snapshot.data!.where((usuario) {
          final String nome = (usuario['nome'] ?? '').toString().toLowerCase();
          return nome.contains(_filtroNome);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar usuário pelo nome...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2D7A1F)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D7A1F), width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: usuariosCadastrados.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: usuariosCadastrados.length,
                      itemBuilder: (context, index) {
                        final usuario = usuariosCadastrados[index];
                        final String nome = usuario['nome'] ?? 'Sem nome';
                        final String email = usuario['email'] ?? 'Sem e-mail';
                        final int rawId = usuario['id'] ?? 0;
                        final bool isBloqueado = usuario['bloqueado'] == true;
                        final bool isDenunciado = usuario['denunciado'] == true;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBloqueado 
                                  ? Colors.red[100] 
                                  : (isDenunciado ? Colors.amber[100] : Colors.blue[100]),
                              child: Icon(
                                isBloqueado 
                                    ? Icons.lock 
                                    : (isDenunciado ? Icons.warning_amber_rounded : Icons.person),
                                color: isBloqueado ? Colors.red : (isDenunciado ? Colors.amber[800] : Colors.blue),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                ),
                                if (isDenunciado) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber[800], borderRadius: BorderRadius.circular(6)),
                                    child: const Text('DENUNCIADO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('ID: $rawId', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(width: 4),
                                if (isDenunciado)
                                  IconButton(
                                    icon: const Icon(Icons.gpp_good, color: Colors.green),
                                    tooltip: 'Ignorar Denúncia',
                                    onPressed: () async {
                                      try {
                                        await AdminService.instance.atualizarUsuario(id: rawId, denunciado: false);
                                        _carregarDados();
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Denúncia cancelada!'), backgroundColor: Colors.green),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(isBloqueado ? Icons.lock_open : Icons.block, color: isBloqueado ? Colors.green : Colors.red),
                                  tooltip: isBloqueado ? 'Desbloquear' : 'Bloquear',
                                  onPressed: () async {
                                    try {
                                      await AdminService.instance.atualizarUsuario(id: rawId, bloqueado: !isBloqueado);
                                      _carregarDados();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isBloqueado ? 'Usuário desbloqueado!' : 'Usuário bloqueado!'),
                                          backgroundColor: isBloqueado ? Colors.green : Colors.red,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
                                    }
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListaDoacoes() {
    return FutureBuilder<List<dynamic>>(
      future: _doacoesAtivasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D7A1F)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar doações.\n${snapshot.error}',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Nenhuma doação ativa cadastrada.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        final listaDoacoes = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: listaDoacoes.length,
          itemBuilder: (context, index) {
            final doacao = listaDoacoes[index];
            final String tituloItem = doacao["titulo"] ?? 'Item sem título';
            final String nomeDoador = doacao["nome_doador"] ?? (doacao["pessoa"]?["nome"] ?? 'Anônimo');
            final String dataPostagem = doacao["data_criacao"] ?? (doacao["created_at"] ?? 'Sem data');

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.orange),
                ),
                title: Text(tituloItem, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Doador: $nomeDoador\nPostado em: $dataPostagem'),
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
      },
    );
  }

  Widget _buildListaPostsDenunciados() {
    return FutureBuilder<List<dynamic>>(
      future: _postsDenunciadosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D7A1F)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar denúncias.\n${snapshot.error}',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Nenhum post denunciado no momento.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        final listaDenuncias = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: listaDenuncias.length,
          itemBuilder: (context, index) {
            final denuncia = listaDenuncias[index];
            final String tituloPost = denuncia['item_titulo'] ?? 'Post sem título';
            final String motivo = denuncia['motivo'] ?? 'Não especificado';
            final String descricao = denuncia['descricao'] ?? '';
            final String doador = denuncia['nome_doador'] ?? 'Desconhecido';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.report_gmailerrorred_rounded, color: Colors.red),
                ),
                title: Text(tituloPost, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Motivo: $motivo\nPublicado por: $doador'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (descricao.isNotEmpty) ...[
                          const Text('Comentários extras do denunciante:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(descricao, style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.check, color: Colors.green),
                              label: const Text('Manter Post', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Denúncia arquivada. O post continua ativo.')),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete_forever, color: Colors.white),
                              label: const Text('Remover Conteúdo'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                // 1. Confirmação com o usuário através do diálogo
                                bool confirmar = await _mostrarDialogoConfirmacao(context);
                                if (!confirmar) return;

                                try {
                                  // 2. Chamar o serviço usando o Singleton do AdminService
                                  await AdminService.instance.removerItemAdmin(denuncia['item_id']);

                                  if (!context.mounted) return;
                                  
                                  // 3. Feedback de sucesso
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Item removido com sucesso!')),
                                  );

                                  // 4. Recarrega as listas da API resetando o estado visual
                                  _carregarDados();

                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                            )
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método do Diálogo de Confirmação integrado perfeitamente dentro da classe do estado
  Future<bool> _mostrarDialogoConfirmacao(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text(
              'Tem certeza que deseja remover permanentemente este item do sistema? '
              'Esta ação removerá o post e suas respectivas denúncias.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}