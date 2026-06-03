import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

const _impactImages = [
  'assets/images/impact1.jpg',
  'assets/images/impact2.jpg',
  'assets/images/impact3.jpg',
];

class ImpactSection extends StatelessWidget {
  const ImpactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final imageHeight = screenWidth < 900 ? 200.0 : 260.0;

    return Container(
      width: double.infinity,
      color: AppColors.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 40 : 80,
      ),
      child: Column(
        children: [
          Text(
            'O Impacto da Generosidade Compartilhada',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: isMobile ? 26 : 32),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Cada item que encontra um novo lar atraves do DoaUTF representa '
              'um passo para longe do consumo linear e um avanco para a sustentabilidade local.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: isMobile ? 15 : 18, height: 1.7),
            ),
          ),
          const SizedBox(height: 60),
          if (isMobile)
            Column(
              children: _impactImages
                  .map((path) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ImpactImage(path: path, height: 200),
                      ))
                  .toList(),
            )
          else
            SizedBox(
              height: imageHeight,
              child: Row(
                children: _impactImages
                    .map(
                      (path) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _ImpactImage(path: path, height: imageHeight),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactImage extends StatelessWidget {
  final String path;
  final double height;
  const _ImpactImage({required this.path, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: 'Foto de impacto social do DoaUTF',
        errorBuilder: (_, __, ___) => Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  path,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
