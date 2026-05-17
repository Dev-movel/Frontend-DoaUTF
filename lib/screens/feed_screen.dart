import 'package:flutter/material.dart';
import '../models/feed_item.dart';
import '../services/doacao_service.dart';
import '../services/feed_service.dart';
import '../services/solicitacao_service.dart';
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
  int _pagina = 1;
  bool _temMaisPaginas = true;

  static const _colunas = 3;
  static const _paddingH = 16.0;
  static const _espacamento = 12.0;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
    _carregarItens(reiniciar: true);
  }

  @override
  void dispose() {
    _buscaController.dispose();
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
          _itens = FeedService.itensMock;
          _temMaisPaginas = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _paginaAnterior() {
    if (_pagina > 1) {
      _pagina--;
      _carregarItens();
    }
  }

  void _proximaPagina() {
    _pagina++;
    _carregarItens();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - _paddingH * 2 - _espacamento * (_colunas - 1)) /
        _colunas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/feed'),
      body: CustomScrollView(
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
                  crossAxisCount: _colunas,
                  mainAxisSpacing: _espacamento,
                  crossAxisSpacing: _espacamento,
                  // imagem quadrada (cardWidth) + área de conteúdo abaixo
                  mainAxisExtent: cardWidth + 185,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _itens[index];
                    return FeedCard(
                      item: item,
                      onTap: () => FeedDetailModal.show(context, item),
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
