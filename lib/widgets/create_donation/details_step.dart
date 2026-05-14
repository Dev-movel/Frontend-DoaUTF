import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/doacao_service.dart';
import '../../theme/app_colors.dart';
import 'shared/form_widgets.dart';

const _kInputBg   = Color(0xFFE3E3DE);
const _kDivider   = Color(0x4DBFCABA);
const _kGreenPill = Color(0x1A2E7D32);

const _conservStates = ['Novo', 'Usado', 'Precisa de reparo'];

class DetailsStep extends StatelessWidget {
  final List<CategoriaItem> categorias;
  final bool loadingCats;
  final String? catsError;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final int? selectedCategoriaId;
  final String selectedConservation;
  final VoidCallback onRetry;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<String> onConservationChanged;

  const DetailsStep({
    super.key,
    required this.categorias,
    required this.loadingCats,
    required this.catsError,
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.selectedCategoriaId,
    required this.selectedConservation,
    required this.onRetry,
    required this.onCategorySelected,
    required this.onConservationChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingCats) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }

    if (catsError != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(catsError!,
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: Colors.redAccent)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: Text('Tentar novamente',
                    style: GoogleFonts.manrope(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    final selected = selectedCategoriaId == null
        ? null
        : categorias.firstWhere(
            (c) => c.id == selectedCategoriaId,
            orElse: () => categorias.first,
          );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Detalhes do Item'),
          const SizedBox(height: 20),
          const FieldLabel('Título da Doação'),
          const SizedBox(height: 8),
          AppTextFormField(
            controller: titleCtrl,
            hint: 'ex: Cadeira de Madeira Vintage',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Informe o título da doação'
                : null,
          ),
          const SizedBox(height: 20),
          const FieldLabel('Categoria'),
          const SizedBox(height: 8),
          _CategorySearchField(
            items: categorias,
            selected: selected,
            onSelected: (cat) => onCategorySelected(cat.id),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Estado do Item'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conservStates
                .map((s) => _ConservBtn(
                      label: s,
                      selected: selectedConservation == s,
                      onTap: () => onConservationChanged(s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Descrição'),
          const SizedBox(height: 8),
          AppTextFormField(
            controller: descCtrl,
            hint: 'Conte a história deste item...',
            maxLines: 5,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Adicione uma descrição'
                : null,
          ),
        ],
      ),
    );
  }
}

class _CategorySearchField extends StatefulWidget {
  final List<CategoriaItem> items;
  final CategoriaItem? selected;
  final ValueChanged<CategoriaItem> onSelected;

  const _CategorySearchField({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_CategorySearchField> createState() => _CategorySearchFieldState();
}

class _CategorySearchFieldState extends State<_CategorySearchField> {
  final _ctrl = TextEditingController();
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) _ctrl.text = widget.selected!.nome;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<CategoriaItem> get _filtered => _ctrl.text.isEmpty
      ? widget.items
      : widget.items
          .where((c) =>
              c.nome.toLowerCase().contains(_ctrl.text.toLowerCase()))
          .toList();

  void _select(CategoriaItem item) {
    widget.onSelected(item);
    _ctrl.text = item.nome;
    setState(() => _showList = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          onTap: () => setState(() => _showList = true),
          onChanged: (_) => setState(() => _showList = true),
          style:
              GoogleFonts.manrope(fontSize: 15, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar categoria...',
            hintStyle:
                GoogleFonts.manrope(fontSize: 15, color: AppColors.outline),
            filled: true,
            fillColor: _kInputBg,
            prefixIcon: const Icon(Icons.search,
                size: 18, color: AppColors.outline),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        if (_showList && _filtered.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kDivider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: _kDivider),
              itemBuilder: (_, i) {
                final cat = _filtered[i];
                final sel = widget.selected?.id == cat.id;
                return Material(
                  color: sel ? _kGreenPill : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    title: Text(
                      cat.nome,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400,
                        color:
                            sel ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                    trailing: sel
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 16)
                        : null,
                    onTap: () => _select(cat),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConservBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ConservBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : _kInputBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.onSurface),
        ),
      ),
    );
  }
}
