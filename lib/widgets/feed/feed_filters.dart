import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FeedFilters extends StatelessWidget {
  final List<String> filtros;
  final String selecionado;
  final ValueChanged<String> onFiltroChanged;
  final TextEditingController buscaController;
  final VoidCallback onBuscar;

  const FeedFilters({
    super.key,
    required this.filtros,
    required this.selecionado,
    required this.onFiltroChanged,
    required this.buscaController,
    required this.onBuscar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filtros.map((filtro) {
                  final isSelected = filtro == selecionado;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onFiltroChanged(filtro),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                          ),
                        ),
                        child: Text(
                          filtro,
                          style: AppTextStyles.input.copyWith(
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 300,
            height: 40,
            child: TextField(
              controller: buscaController,
              onSubmitted: (_) => onBuscar(),
              textAlignVertical: TextAlignVertical.center,
              style: AppTextStyles.input,
              decoration: InputDecoration(
                hintText: 'Buscar doações...',
                hintStyle: AppTextStyles.hint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.outline,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: buscaController,
                  builder: (_, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.outline,
                          ),
                          onPressed: () {
                            buscaController.clear();
                            onBuscar();
                          },
                        ),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
