import 'package:flutter/material.dart';
import '../models/premio.dart';
import '../services/premios_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/main_app_bar.dart';

class PremiacoesScreen extends StatefulWidget {
  const PremiacoesScreen({super.key});

  @override
  State<PremiacoesScreen> createState() => _PremiacoesScreenState();
}

class _PremiacoesScreenState extends State<PremiacoesScreen> {
  int _saldo = 0;
  bool _carregando = true;
  bool _resgatando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final saldo = await PremiosService.instance.buscarSaldo();
    if (mounted) setState(() { _saldo = saldo; _carregando = false; });
  }

  Future<void> _confirmarResgate(Premio premio) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar resgate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você está resgatando:',
                style: AppTextStyles.label.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(premio.nome,
                style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('${premio.custo} pontos',
                    style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Após o resgate, apresente o código de confirmação no Bloco E, sala 105 para retirar seu prêmio.',
              style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resgatar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _resgatando = true);
    try {
      final resultado = await PremiosService.instance.resgatar(premio.id);
      final codigo = resultado['codigo'] as String? ?? '';
      final saldoRestante = int.tryParse('${resultado['saldo_restante'] ?? 0}') ?? 0;

      if (mounted) {
        setState(() { _saldo = saldoRestante; _resgatando = false; });
        _mostrarSucesso(premio, codigo, saldoRestante);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resgatando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('saldo')
                ? 'Saldo insuficiente para este resgate.'
                : 'Erro ao realizar resgate. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarSucesso(Premio premio, String codigo, int saldoRestante) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 64),
            const SizedBox(height: 16),
            Text('Resgate realizado!',
                style: AppTextStyles.headline.copyWith(fontSize: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Seu prêmio "${premio.nome}" foi resgatado com sucesso.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text('Código de retirada',
                      style: AppTextStyles.label.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(codigo,
                      style: AppTextStyles.headline.copyWith(
                          fontSize: 22, color: AppColors.primary, letterSpacing: 3)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Apresente este código no Bloco E, sala 105. Um e-mail de confirmação foi enviado para você.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text('Saldo restante: $saldoRestante pontos',
                style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final colunas = largura < 500 ? 2 : (largura < 900 ? 3 : 4);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MainAppBar(activeRoute: '/premiacoes'),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _carregar,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: colunas,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _CardPremio(
                          premio: Premio.catalogo[i],
                          saldo: _saldo,
                          resgatando: _resgatando,
                          onResgatar: () => _confirmarResgate(Premio.catalogo[i]),
                        ),
                        childCount: Premio.catalogo.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white70, size: 36),
          const SizedBox(height: 8),
          Text('Seus pontos', style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '$_saldo',
            style: AppTextStyles.headline.copyWith(
                color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('pontos disponíveis',
              style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Ganhe até 10 pontos por doação',
                  style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de prêmio ─────────────────────────────────────────────────────────

class _CardPremio extends StatelessWidget {
  final Premio premio;
  final int saldo;
  final bool resgatando;
  final VoidCallback onResgatar;

  const _CardPremio({
    required this.premio,
    required this.saldo,
    required this.resgatando,
    required this.onResgatar,
  });

  @override
  Widget build(BuildContext context) {
    final temPontos = saldo >= premio.custo;
    final faltam = premio.custo - saldo;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: temPontos ? 1.0 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: temPontos
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.outline.withOpacity(0.15),
            width: temPontos ? 1.5 : 1,
          ),
          boxShadow: temPontos
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Imagem do prêmio
                  AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: temPontos
                          ? Image.asset(
                              premio.imagem,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.card_giftcard_outlined,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            )
                          : ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ]),
                              child: Image.asset(
                                premio.imagem,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.card_giftcard_outlined,
                                  size: 40,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nome
                  Text(
                    premio.nome,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.input.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: temPontos ? AppColors.onSurface : AppColors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Custo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded,
                          size: 13,
                          color: temPontos ? AppColors.primary : AppColors.outline),
                      const SizedBox(width: 3),
                      Text(
                        '${premio.custo} pts',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: temPontos ? AppColors.primary : AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Botão ou faltam X
                  if (temPontos)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: resgatando ? null : onResgatar,
                        child: Text('Resgatar',
                            style: AppTextStyles.label.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.outline.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 11, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Faltam $faltam pts',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Badge "disponível"
            if (temPontos)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('✓',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
