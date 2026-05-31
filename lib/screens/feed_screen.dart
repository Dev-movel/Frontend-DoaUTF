import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../screens/agendamento_screen.dart';
import '../services/doacao_service.dart';
import '../services/feed_service.dart';
import '../services/solicitacao_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../widgets/main_app_bar.dart';
import '../widgets/feed/feed_card.dart';
import '../widgets/feed/feed_detail_modal.dart';
import '../widgets/feed/feed_filters.dart';
import '../widgets/feed/feed_header.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool _isLoading = false;
  List<FeedItem> _itens = [];
  List<String> _filtros = ['Todos'];
  String _filtroSelecionado = 'Todos';
  final _buscaController = TextEditingController();
  final _scrollController = ScrollController();
  int _pagina = 1;
  bool _temMaisPaginas = true;
  int? _usuarioAtualId;

  static const _paddingH = 16.0;
  static const _espacamento = 12.0;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregarCategorias();
    _carregarItens(reiniciar: true);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    try {
      final categorias = await DoacaoService.instance.buscarCategorias();
      if (mounted) {
        setState(() {
          final nomes = categorias.map((c) => c.nome).toList();
          final outros = nomes.remove('Outros');
          if (outros) nomes.add('Outros');
          _filtros = ['Todos', ...nomes];
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarItens({bool reiniciar = false}) async {
    if (reiniciar) _pagina = 1;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FeedService.instance.buscarItens(
          categoria: _filtroSelecionado == 'Todos' ? null : _filtroSelecionado,
          busca: _buscaController.text.isEmpty ? null : _buscaController.text,
          pagina: _pagina,
        ),
        SolicitacaoService.instance.buscarMinhasSolicitacoes(),
      ]);

      final itens = results[0] as List<FeedItem>;
      final solicitacoes = results[1] as Map<int, int>;

      final itensCruzados = itens.map((item) {
        final solId = solicitacoes[item.id];
        return solId != null ? item.copyWith(solicitacaoId: solId) : item;
      }).toList();

      if (mounted) {
        setState(() {
          _itens = itensCruzados;
          _temMaisPaginas = itens.length >= 9;
        });
      }
    } catch (_) {
      if (mounted && reiniciar) {
        setState(() {
          _itens = [];
          _temMaisPaginas = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarUsuario() async {
    try {
      final usuario = await UsuarioService.instance.getMe();
      if (mounted) setState(() => _usuarioAtualId = usuario.id);
    } catch (_) {
      // sem usuário, continuamos sem ações específicas do proprietário
    }
  }

  Future<void> _abrirAgendamento(FeedItem item) async {
    if (_usuarioAtualId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o agendamento. Faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgendamentoScreen(
          itemId: item.id,
          usuarioIdAtual: _usuarioAtualId!,
          doadorId: item.doadorId,
        ),
      ),
    );

    if (mounted) {
      await _carregarItens(reiniciar: true);
    }
  }

  Future<void> _aceitarSolicitacaoEabrirAgendamento(int solicitacaoId, FeedItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SolicitacaoService.instance.aceitarSolicitacao(solicitacaoId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Solicitação aceita! Abrindo agenda...'),
          backgroundColor: Color(0xFF0D631B),
        ),
      );
      await _carregarItens(reiniciar: true);
      _abrirAgendamento(item);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao aceitar solicitação: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _abrirAceitarSolicitacao(FeedItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final solicitacoes = await SolicitacaoService.instance.buscarSolicitacoesDoItem(item.id);
      final pendentes = solicitacoes.where((s) => s['status'] == 'pendente').toList();

      if (pendentes.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Não há solicitações pendentes para este item.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (pendentes.length == 1) {
        await _aceitarSolicitacaoEabrirAgendamento(pendentes.first['id'] as int, item);
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Escolha uma solicitação'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pendentes.length,
              itemBuilder: (context, index) {
                final solicitacao = pendentes[index];
                final solicitante = solicitacao['solicitante'] ?? {};
                final nome = solicitante['nome'] ?? 'Usuário interessado';

                return ListTile(
                  title: Text(nome),
                  subtitle: Text('ID: ${solicitacao['id']}'),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _aceitarSolicitacaoEabrirAgendamento(solicitacao['id'] as int, item);
                    },
                    child: const Text('Aceitar'),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao carregar solicitações: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _paginaAnterior() async {
    if (_pagina > 1) {
      _pagina--;
      await _carregarItens();
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  Future<void> _proximaPagina() async {
    _pagina++;
    await _carregarItens();
    if (mounted && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final colunas = screenWidth < 600 ? 1 : (screenWidth < 900 ? 2 : 3);
    final cardWidth =
        (screenWidth - _paddingH * 2 - _espacamento * (colunas - 1)) /
        colunas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/feed'),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header e filtros scrollam junto com o conteúdo
          const SliverToBoxAdapter(child: FeedHeader()),
          SliverToBoxAdapter(
            child: FeedFilters(
              filtros: _filtros,
              selecionado: _filtroSelecionado,
              onFiltroChanged: (filtro) {
                setState(() => _filtroSelecionado = filtro);
                _carregarItens(reiniciar: true);
              },
              buscaController: _buscaController,
              onBuscar: () => _carregarItens(reiniciar: true),
            ),
          ),

          if (_isLoading && _itens.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _paddingH,
                8,
                _paddingH,
                8,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: colunas,
                  mainAxisSpacing: _espacamento,
                  crossAxisSpacing: _espacamento,
                  // imagem quadrada (cardWidth) + área de conteúdo abaixo
                  mainAxisExtent: cardWidth + 245,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, index) {
                    final item = _itens[index];
                    final statusLower = item.status.toLowerCase();
                    final isOwner = item.doadorId != null && item.doadorId == _usuarioAtualId;
                    final canAcceptDirect = isOwner && statusLower == 'disponivel';
                    final canOpenAgendamento = (statusLower == 'reservado' || statusLower == 'agendado') &&
                        (isOwner || item.solicitacaoId != null);

                    return FeedCard(
                      item: item,
                      onTap: () async {
                        final savedOffset = _scrollController.hasClients
                            ? _scrollController.offset
                            : 0.0;
                        await FeedDetailModal.show(context, item);
                        if (mounted) {
                          await _carregarItens();
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(savedOffset);
                          }
                        }
                      },
                      onAcceptDirect: canAcceptDirect ? () => _abrirAceitarSolicitacao(item) : null,
                      onOpenAgendamento: canOpenAgendamento ? () => _abrirAgendamento(item) : null,
                    );
                  },
                  childCount: _itens.length,
                ),
              ),
            ),

            // Paginação no fim do conteúdo scrollável
            SliverToBoxAdapter(child: _buildPaginacao()),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginacao() {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.onSurface,
      side: const BorderSide(color: AppColors.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: (_isLoading || _pagina <= 1) ? null : _paginaAnterior,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('anterior'),
            style: buttonStyle,
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed:
                (_isLoading || !_temMaisPaginas) ? null : _proximaPagina,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('próxima'),
            iconAlignment: IconAlignment.end,
            style: buttonStyle,
          ),
        ],
      ),
    );
  }
}
