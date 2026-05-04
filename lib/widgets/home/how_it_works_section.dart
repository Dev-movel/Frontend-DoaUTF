import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Column(
        children: [
          Text(
            'Como funciona',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 42),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Publique com Facilidade',
                description:
                    'Cadastre itens para doação em poucos passos: basta uma foto e uma breve descrição.',
              ),
              _FeatureCard(
                icon: Icons.handshake_outlined,
                title: 'Encontro Seguro',
                description:
                    'A entrega acontece presencialmente em locais públicos dentro do próprio campus da UTFPR, somente entre membros da universidade.',
              ),
              _FeatureCard(
                icon: Icons.eco_outlined,
                title: 'Impacto Ambiental',
                description:
                    'Acompanhe sua contribuição ambiental em tempo real.',
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

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // largura mínima responsiva em vez de fixo
      width: 250,
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