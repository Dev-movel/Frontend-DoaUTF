import 'package:flutter/material.dart';
import '../../models/feed_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../mapa/modal_mapa_local.dart';
import '../../services/denuncia_service.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onReport;

  const FeedCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            _Imagem(
              fotoUrl: item.fotoUrl,
              status: item.status,
              itemId: item.id,
              onReport: onReport,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _CategoriaChip(categoria: item.categoria),
                    const SizedBox(height: 6),
                    Text(
                      item.titulo,
                      style: AppTextStyles.featureTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.descricao ?? '',
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _DoadorRow(item: item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Imagem extends StatelessWidget {
  final String? fotoUrl;
  final String status;
  final dynamic itemId;
  final VoidCallback? onReport;

  const _Imagem({
    required this.fotoUrl,
    required this.status,
    required this.itemId,
    this.onReport,
  });

  String get _label {
    switch (status.toLowerCase()) {
      case 'reservado':
        return 'Reservado';
      case 'doado':
        return 'Doado';
      default:
        return 'Disponível';
    }
  }

  Color get _badgeColor {
    switch (status.toLowerCase()) {
      case 'reservado':
        return Colors.orange;
      case 'doado':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  void _mostrarModalDenunciaInterno(BuildContext context) {
    String motivoSelecionado = 'Item inadequado ou ofensivo';
    final TextEditingController descricaoController = TextEditingController();

    final List<String> motivos = [
      'Item inadequado ou ofensivo',
      'Fraude, golpe ou anúncio falso',
      'Item proibido por lei',
      'Categoria errada ou spam',
      'Outro motivo',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Denunciar Post'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione o motivo principal:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: motivoSelecionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: motivos.map((String motivo) {
                        return DropdownMenuItem<String>(
                          value: motivo,
                          child: Text(motivo, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (novoMotivo) {
                        setDialogState(() {
                          motivoSelecionado = novoMotivo!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detalhes adicionais (opcional)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final motivo = motivoSelecionado;
                    final descricao = descricaoController.text;

                    Navigator.pop(context);

                    if (onReport != null) {
                      onReport!();
                    } else {
                      try {
                        await DenunciaService.instance.enviarDenuncia(
                          itemId: itemId.toString(),
                          motivo: motivo,
                          descricao: descricao,
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Denúncia registrada! O administrador irá analisar.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao enviar denúncia: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Enviar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: fotoUrl != null
              ? Image.network(
                  fotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Placeholder(),
                )
              : _Placeholder(),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _label,
              style: AppTextStyles.badge.copyWith(color: Colors.white),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            radius: 18,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.report_outlined, size: 20, color: Colors.white),
              tooltip: 'Denunciar esta publicação',
              onPressed: () => _mostrarModalDenunciaInterno(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.containerHigh,
      child: const Center(
        child:
            Icon(Icons.image_outlined, color: AppColors.outline, size: 32),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoriaChip extends StatelessWidget {
  final String categoria;
  const _CategoriaChip({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        categoria.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DoadorRow extends StatelessWidget {
  final FeedItem item;
  const _DoadorRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final inicial = item.doadorNome.isNotEmpty
        ? item.doadorNome[0].toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Text(
            inicial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.doadorNome,
                style: AppTextStyles.input,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // ── Localização (botão) + tempo ──────────────────────
              Row(
                children: [
                  // Botão de localização — abre o modal do mapa
                  GestureDetector(
                    onTap: () => ModalMapaLocal.mostrar(
                      context,
                      localizacao: item.localizacao,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.localizacao,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Separador e tempo
                  Text(
                    ' • ${item.tempoAtras}',
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
