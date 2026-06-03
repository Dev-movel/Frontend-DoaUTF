import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/modal_helper.dart';

class CommunitySection extends StatelessWidget {
  const CommunitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      padding: EdgeInsets.all(isMobile ? 32 : 60),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            'Faça parte do movimento da generosidade.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sideTitle.copyWith(
              color: Colors.white,
              fontSize: isMobile ? 22 : 28,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => ModalHelper.openSignup(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 28 : 40,
                vertical: 20,
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Criar Conta Gratuitamente'),
          ),
        ],
      ),
    );
  }
}

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: 40,
      ),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 20),
          Text(
            '© 2024 DoaUTF - Tecnologia para o Bem Comum',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
