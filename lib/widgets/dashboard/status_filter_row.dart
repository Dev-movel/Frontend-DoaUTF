import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StatusFilterRow extends StatelessWidget {
  final List<String> filtros;
  final String statusSelecionado;
  final ValueChanged<String> onStatusChanged;

  const StatusFilterRow({
    super.key,
    required this.filtros,
    required this.statusSelecionado,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = filtros[index];
          final isSelected = filtro == statusSelecionado;

          return ChoiceChip(
            label: Text(filtro),
            selected: isSelected,
            onSelected: (selected) {
              if (selected && filtro != statusSelecionado) {
                onStatusChanged(filtro);
              }
            },
            selectedColor: AppColors.primaryContainer,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}