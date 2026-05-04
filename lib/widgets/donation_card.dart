import 'package:flutter/material.dart';
import '../models/doacao.dart';
import '../theme/app_colors.dart';
import 'status_badge.dart';

class DonationCard extends StatelessWidget {
  final Doacao doacao;

  const DonationCard({Key? key, required this.doacao}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.containerHigh,
                borderRadius: BorderRadius.circular(8),
                image: doacao.fotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(doacao.fotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: doacao.fotoUrl == null
                  ? const Icon(Icons.image_not_supported, color: AppColors.outline)
                  : null,
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(status: doacao.status),
                  const SizedBox(height: 8),
                  Text(
                    doacao.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}