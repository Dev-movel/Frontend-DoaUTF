import 'package:flutter/material.dart';
import '../../models/feed_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onAcceptDirect;
  final VoidCallback? onOpenAgendamento;

  const FeedCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onAcceptDirect,
    this.onOpenAgendamento,
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
            _Imagem(fotoUrl: item.fotoUrl, status: item.status),
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
                    if (onAcceptDirect != null || onOpenAgendamento != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (onOpenAgendamento != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onOpenAgendamento,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Ver agendamento'),
                              ),
                            ),
                          if (onOpenAgendamento != null && onAcceptDirect != null)
                            const SizedBox(width: 8),
                          if (onAcceptDirect != null)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onAcceptDirect,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Aceitar'),
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _Imagem extends StatelessWidget {
  final String? fotoUrl;
  final String status;
  const _Imagem({required this.fotoUrl, required this.status});

  String get _label {
    switch (status.toLowerCase()) {
      case 'reservado': return 'Reservado';
      case 'doado': return 'Doado';
      default: return 'Disponível';
    }
  }

  Color get _badgeColor {
    switch (status.toLowerCase()) {
      case 'reservado': return Colors.orange;
      case 'doado': return Colors.grey;
      default: return AppColors.primary;
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.containerHigh,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.outline, size: 32),
      ),
    );
  }
}

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
              Text(
                '${item.localizacao} • ${item.tempoAtras}',
                style: AppTextStyles.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
