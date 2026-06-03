// lib/widgets/mapa/modal_mapa_local.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/mapa_controller.dart';

/// Uso em qualquer lugar:
///   ModalMapaLocal.mostrar(context, localizacao: item.localizacao);
class ModalMapaLocal {
  static void mostrar(BuildContext context, {required String localizacao}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _ConteudoModalMapa(localizacao: localizacao),
    );
  }
}

class _ConteudoModalMapa extends StatefulWidget {
  final String localizacao;
  const _ConteudoModalMapa({required this.localizacao});

  @override
  State<_ConteudoModalMapa> createState() => _ConteudoModalMapaState();
}

class _ConteudoModalMapaState extends State<_ConteudoModalMapa>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  PontoNoMapa? _ponto;

  @override
  void initState() {
    super.initState();
    _ponto = buscarPontoPorNome(widget.localizacao);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double alturaModal = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: alturaModal,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.localizacao,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _ponto == null
                ? _LocalNaoEncontrado(localizacao: widget.localizacao)
                : _MapaComDestaque(
                    ponto: _ponto!,
                    pulseAnimation: _pulseAnimation,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapaComDestaque extends StatelessWidget {
  final PontoNoMapa ponto;
  final Animation<double> pulseAnimation;

  const _MapaComDestaque({required this.ponto, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double svgW = 2200;
        const double svgH = 1700;
        final double escala = (constraints.maxWidth / svgW).clamp(0.1, 1.0);
        final double largura = svgW * escala;
        final double altura = svgH * escala;
        final Offset posEscalada = Offset(
          ponto.posicao.dx * escala,
          ponto.posicao.dy * escala,
        );

        return InteractiveViewer(
          maxScale: 5.0,
          minScale: 1.0,
          child: Center(
            child: SizedBox(
              width: largura,
              height: altura,
              child: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/images/file.svg',
                    width: largura,
                    height: altura,
                    fit: BoxFit.contain,
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PintorPulso(
                        posicao: posEscalada,
                        animacao: pulseAnimation,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LocalNaoEncontrado extends StatelessWidget {
  final String localizacao;
  const _LocalNaoEncontrado({required this.localizacao});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '"$localizacao" não encontrado no mapa',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PintorPulso extends CustomPainter {
  final Offset posicao;
  final Animation<double> animacao;

  _PintorPulso({required this.posicao, required this.animacao})
      : super(repaint: animacao);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      posicao,
      18.0 * animacao.value,
      Paint()..color = Colors.amber.withOpacity(0.35),
    );
    canvas.drawCircle(posicao, 10.0, Paint()..color = Colors.amber[800]!);
    canvas.drawCircle(
      posicao,
      10.0,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorPulso old) => old.posicao != posicao;
}