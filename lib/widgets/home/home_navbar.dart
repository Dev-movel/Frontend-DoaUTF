import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/modal_helper.dart';

class HomeNavbar extends StatelessWidget {
  const HomeNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DoaUTF',
            style: AppTextStyles.headline.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (isMobile)
            const _MobileMenuButton()
          else
            Row(
              children: [
                TextButton(
                  onPressed: () => ModalHelper.openLogin(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                  ),
                  child: const Text('Login'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => ModalHelper.openSignup(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cadastrar'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Menu hambúrguer para mobile
class _MobileMenuButton extends StatelessWidget {
  const _MobileMenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'login') ModalHelper.openLogin(context);
        if (value == 'signup') ModalHelper.openSignup(context);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'login',
          child: Row(
            children: [
              Icon(Icons.login_outlined),
              SizedBox(width: 12),
              Text('Login'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'signup',
          child: Row(
            children: [
              Icon(Icons.person_add_outlined),
              SizedBox(width: 12),
              Text('Cadastrar'),
            ],
          ),
        ),
      ],
    );
  }
}