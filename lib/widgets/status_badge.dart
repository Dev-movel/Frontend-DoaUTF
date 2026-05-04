import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'AGUARDANDO RETIRADA':
        bgColor = AppColors.statusAguardandoBg;
        textColor = AppColors.statusAguardandoText;
        break;
      case 'ANUNCIADO':
        bgColor = AppColors.statusAnunciadoBg;
        textColor = AppColors.statusAnunciadoText;
        break;
      case 'CONCLUÍDO':
      case 'CONCLUIDO':
        bgColor = AppColors.statusConcluidoBg;
        textColor = AppColors.statusConcluidoText;
        break;
      case 'CANCELADO':
      default:
        bgColor = AppColors.statusCanceladoBg;
        textColor = AppColors.statusCanceladoText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}