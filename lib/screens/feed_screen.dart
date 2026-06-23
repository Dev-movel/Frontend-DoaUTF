import 'package:flutter/material.dart';
import '../models/feed_item.dart';
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
  int? _meuId;
  final _buscaController = TextEditingController();
  final _scrollController = ScrollController();
  int _pagina = 1;
  bool _temMaisPaginas = true;

  static const _paddingH = 16.0;
  static const _espacamento = 12.0;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _carregarMeuId().then((_) => _carregarItens(reiniciar: true));
  }

  Future<void> _carregarMeuId() async {
    try {
      final user = await UsuarioService.instance.getMe();
      if (mounted) setState(() => _meuId = user.id);
    } catch (_) {}
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

      final itensCruzados = itens
          .where((item) =>
              item.status.toLowerCase() != 'doado' &&
              (_meuId == null || item.doadorId != _meuId))
          .map((item) {
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
