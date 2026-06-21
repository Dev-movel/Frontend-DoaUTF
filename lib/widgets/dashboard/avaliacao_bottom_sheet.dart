import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:dio/dio.dart';
import '../../services/avaliacao_service.dart';
import '../../theme/app_colors.dart';

/// Modal de avaliação para o usuário avaliar após conclusão de doação.
/// 
/// Uso:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => AvaliacaoBottomSheet(
///     itemId: 15,
///     usuarioParaBreviarNome: "João Silva",
///     onSuccess: () => _recarregarDashboard(),
///   ),
/// );
/// ```
class AvaliacaoBottomSheet extends StatefulWidget {
  final int itemId;

  final String usuarioParaBreviarNome;

  final VoidCallback? onSuccess;

  const AvaliacaoBottomSheet({
    super.key,
    required this.itemId,
    required this.usuarioParaBreviarNome,
    this.onSuccess,
  });

  @override
  State<AvaliacaoBottomSheet> createState() => _AvaliacaoBottomSheetState();
}

class _AvaliacaoBottomSheetState extends State<AvaliacaoBottomSheet> {
  late int _nota;
  late TextEditingController _comentarioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nota = 0; 
    _comentarioController = TextEditingController();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarAvaliacao() async {
    if (_nota == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma nota antes de enviar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AvaliacaoService.instance.enviarAvaliacao(
        itemId: widget.itemId,
        nota: _nota,
        comentario: _comentarioController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Avaliação enviada com sucesso!'),
          backgroundColor: const Color(0xFF2D7A1F),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      widget.onSuccess?.call();

      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;

      String mensagem = 'Erro ao enviar avaliação.';

      switch (e.response?.statusCode) {
        case 403:
          mensagem = e.response?.data?['erro'] ?? 'O item ainda não foi entregue.';
        case 409:
          mensagem = 'Você já avaliou esta doação.';
        case 410:
          mensagem = 'O prazo de 7 dias para avaliar expirou.';
        case 422:
          mensagem = e.response?.data?['erro'] ?? 'Dados inválidos.';
        default:
          mensagem = 'Erro ao enviar avaliação. Tente novamente.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline,
                        color: Color(0xFFF57C00), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Avaliar Experiência',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Como foi sua experiência com ${widget.usuarioParaBreviarNome}?',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: Colors.black38, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Center(
                  child: Column(
                    children: [
                      RatingBar.builder(
                        initialRating: _nota.toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemSize: 48,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 6),
                        itemBuilder: (_, index) => const Icon(
                          Icons.star,
                          color: Color(0xFFF57C00),
                        ),
                        onRatingUpdate: (rating) {
                          setState(() => _nota = rating.toInt());
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_nota > 0)
                        Text(
                          _getNotaLabel(_nota),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getNotaColor(_nota),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Comentário (Opcional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _comentarioController,
                  maxLines: 3,
                  maxLength: 500,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Compartilhe detalhes sobre sua experiência...',
                    hintStyle: const TextStyle(color: Colors.black38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: const TextStyle(fontSize: 11),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: (_nota > 0 && !_isLoading)
                        ? _enviarAvaliacao
                        : null, // Desabilitado se nota == 0
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A1F),
                      disabledBackgroundColor: const Color(0xFFBDBDBD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enviar Avaliação',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFEEEEEE),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNotaLabel(int nota) {
    switch (nota) {
      case 1:
        return 'Não recomendo';
      case 2:
        return 'Precisa melhorar';
      case 3:
        return 'Aceitável';
      case 4:
        return 'Muito bom';
      case 5:
        return 'Excelente!';
      default:
        return '';
    }
  }

  Color _getNotaColor(int nota) {
    switch (nota) {
      case 1:
        return const Color(0xFFD32F2F); 
      case 2:
        return const Color(0xFFFF9800); 
      case 3:
        return const Color(0xFFFBC02D); 
      case 4:
        return const Color(0xFF8BC34A); 
      case 5:
        return const Color(0xFF2D7A1F);
      default:
        return Colors.black38;
    }
  }
}