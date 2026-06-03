// lib/screens/tela_mapa.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/mapa_controller.dart';

class TelaDoMapa extends StatefulWidget {
  const TelaDoMapa({super.key});

  @override
  State<TelaDoMapa> createState() => _TelaDoMapaState();
}

class _TelaDoMapaState extends State<TelaDoMapa>
    with SingleTickerProviderStateMixin {
  String? _nomeSelecionado; // guarda o nome do local (ex: "Bloco A")
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _abrirModalDeLocais() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Alça
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Onde você quer ser encontrado?",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Lista de locais usando pontosDoMapa
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: pontosDoMapa.map((ponto) {
                        final bool selecionado =
                            ponto.nome == _nomeSelecionado;
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: selecionado
                                ? Colors.amber[800]
                                : Colors.grey,
                          ),
                          title: Text(ponto.nome),
                          tileColor: selecionado
                              ? Colors.amber.withOpacity(0.15)
                              : null,
                          trailing: selecionado
                              ? const Icon(Icons.check,
                                  color: Colors.amber)
                              : null,
                          onTap: () {
                            setState(
                                () => _nomeSelecionado = ponto.nome);
                            _pulseController.repeat(reverse: true);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Busca pelo nome selecionado
    final pontoDestacado = _nomeSelecionado != null
        ? buscarPontoPorNome(_nomeSelecionado!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rotas UTFPR-CM"),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        elevation: 2,
        bottom: pontoDestacado != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        pontoDestacado.nome,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double svgW = 1200;
          const double svgH = 900;
          final double escala =
              (constraints.maxWidth / svgW).clamp(0.1, 1.0);
          final double largura = svgW * escala;
          final double altura = svgH * escala;

          final Offset? posEscalada = pontoDestacado != null
              ? Offset(
                  pontoDestacado.posicao.dx * escala,
                  pontoDestacado.posicao.dy * escala,
                )
              : null;

          return Stack(
            children: [
              InteractiveViewer(
                maxScale: 6.0,
                minScale: 0.8,
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
                        if (posEscalada != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PintorPulso(
                                posicao: posEscalada,
                                animacao: _pulseAnimation,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (pontoDestacado == null)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Toque em + para escolher um local",
                        style:
                            TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalDeLocais,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add_location_alt),
        label: Text(
          pontoDestacado != null ? "Trocar local" : "Escolher local",
        ),
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
    canvas.drawCircle(posicao, 10.0,
        Paint()..color = Colors.amber[800]!);
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
  bool shouldRepaint(covariant _PintorPulso old) =>
      old.posicao != posicao;
}