import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FeedHeader extends StatelessWidget {
  const FeedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feed de Doações', style: AppTextStyles.headline),
          const SizedBox(height: 4),
          Text(
            'Encontre itens que precisam de um novo lar',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
