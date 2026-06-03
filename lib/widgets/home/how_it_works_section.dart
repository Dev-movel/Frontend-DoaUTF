import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final cardWidth = screenWidth < 500 ? (screenWidth - 40).clamp(200.0, 250.0) : 250.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            'Como funciona',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: isMobile ? 32 : 42),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: isMobile ? 24 : 40,
            runSpacing: isMobile ? 32 : 40,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Publique com Facilidade',
                description:
                    'Cadastre itens para doação em poucos passos: basta uma foto e uma breve descrição.',
                cardWidth: cardWidth,
              ),
              _FeatureCard(
                icon: Icons.handshake_outlined,
                title: 'Encontro Seguro',
                description:
                    'A entrega acontece presencialmente em locais públicos dentro do próprio campus da UTFPR, somente entre membros da universidade.',
                cardWidth: cardWidth,
              ),
              _FeatureCard(
                icon: Icons.eco_outlined,
                title: 'Impacto Ambiental',
                description:
                    'Acompanhe sua contribuição ambiental em tempo real.',
                cardWidth: cardWidth,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double cardWidth;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: Column(
        children: [
          Semantics(
            label: title,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.featureTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
