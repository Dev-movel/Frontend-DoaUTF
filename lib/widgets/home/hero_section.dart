import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/modal_helper.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 32 : 40),
        vertical: isMobile ? 40 : 60,
      ),
      child: (isMobile || isTablet)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeroText(isMobile: isMobile || isTablet),
                const SizedBox(height: 50),
                _HeroImage(isMobile: isMobile || isTablet, isTablet: isTablet),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _HeroText(isMobile: false)),
                const SizedBox(width: 60),
                Expanded(child: _HeroImage(isMobile: false, isTablet: false)),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool isMobile;
  const _HeroText({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final heroFontSize = isMobile
        ? 36.0
        : (screenWidth < 1100 ? 50.0 : 64.0);

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Dê nova vida ao\nque você não\nprecisa mais.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: AppTextStyles.hero.copyWith(
            fontSize: heroFontSize,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Uma rede logística contínua para a generosidade.\n'
          'Conecte-se com colegas, recicle itens e acompanhe\n'
          'sua contribuição ambiental em tempo real.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: AppTextStyles.subtitle.copyWith(fontSize: 18, height: 1.6),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => ModalHelper.openSignup(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Começar Agora'),
            ),
            OutlinedButton(
              onPressed: () => ModalHelper.openLogin(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 22,
                ),
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Fazer Login',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  const _HeroImage({required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final imageHeight = isMobile ? 280.0 : (isTablet ? 380.0 : 550.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/home.jpg',
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: 'Pessoas colaborando em doações comunitárias',
        errorBuilder: (context, error, stackTrace) => Container(
          height: imageHeight,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Adicione assets/images/home.jpg',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}