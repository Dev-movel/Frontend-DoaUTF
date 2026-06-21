import 'package:flutter/material.dart';
import '../../models/feed_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../mapa/modal_mapa_local.dart';

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
                    const SizedBox(height: 8),
                    _TituloELocalizacao(item: item),
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

  @override
  Widget build(BuildContext context) {
    final bool indisponivel = status.toLowerCase() != 'disponivel';

    return Stack(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.containerHigh,
            image: fotoUrl != null
                ? DecorationImage(
                    image: NetworkImage(fotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: fotoUrl == null
              ? const Icon(
                  Icons.image_not_supported_outlined,
                  size: 60,
                  color: AppColors.outline,
                )
              : null,
        ),
        if (indisponivel)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final String categoria;
  const _CategoriaChip({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primaryContainer.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        categoria,
        style: AppTextStyles.subtitle.copyWith(
          color: AppColors.primaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TituloELocalizacao extends StatelessWidget {
  final FeedItem item;
  const _TituloELocalizacao({required this.item});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.titulo,
                style: AppTextStyles.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 13, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Doado por ${item.doadorNome}',
                      style: AppTextStyles.subtitle.copyWith(color: AppColors.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => ModalMapaLocal.mostrar(
                  context,
                  localizacao: item.localizacao,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 13,
                      color: AppColors.primaryContainer,
                    ),
                    SizedBox(width: 2),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => ModalMapaLocal.mostrar(
                    context,
                    localizacao: item.localizacao,
                  ),
                  child: Text(
                    item.localizacao,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primaryContainer,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                ' • ${item.tempoAtras}',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}