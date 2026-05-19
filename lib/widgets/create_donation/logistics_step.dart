import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'shared/form_widgets.dart';

const _kInputBg   = Color(0xFFE3E3DE);
const _kDivider   = Color(0x4DBFCABA);
const _kGreenPill = Color(0x1A2E7D32);
const _kSelBorder = Color(0x330D631B);

const _meetingPoints = [
  'Bloco A',
  'Bloco B',
  'Bloco C',
  'Bloco D',
  'Bloco E',
  'Bloco F',
  'Bloco G',
  'Biblioteca',
  'Centro de Convivência',
  'Aquário',
  'RU',
];

class LogisticsStep extends StatefulWidget {
  final String tipoLogistica;
  final String localRetirada;
  final ValueChanged<String> onTipoChanged;
  final ValueChanged<String> onLocalSelected;

  const LogisticsStep({
    super.key,
    required this.tipoLogistica,
    required this.localRetirada,
    required this.onTipoChanged,
    required this.onLocalSelected,
  });

  @override
  State<LogisticsStep> createState() => _LogisticsStepState();
}

class _LogisticsStepState extends State<LogisticsStep> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _meetingPoints
        .where((p) => p.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Logística'),
        const SizedBox(height: 20),
        _LogisticCard(
          icon: Icons.location_on_outlined,
          iconColor: AppColors.primary,
          title: 'Retirada Disponível',
          subtitle: 'Escolha o bloco/ponto onde o item pode ser retirado.',
          selected: widget.tipoLogistica == 'retirada',
          onTap: () => widget.onTipoChanged('retirada'),
        ),
        const SizedBox(height: 12),
        _LogisticCard(
          icon: Icons.meeting_room_outlined,
          iconColor: AppColors.onSurfaceVariant,
          title: 'Ponto de Encontro',
          subtitle: 'Combine um local no campus da UTF!',
          selected: widget.tipoLogistica == 'encontro',
          onTap: () => widget.onTipoChanged('encontro'),
        ),
        const SizedBox(height: 24),
        const FieldLabel('Local de Retirada / Ponto de Encontro'),
        const SizedBox(height: 8),
        AppInput(
          hint: 'Buscar local...',
          prefixIcon: Icons.search,
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text('Nenhum resultado',
                        style: GoogleFonts.manrope(
                            color: AppColors.outline, fontSize: 14)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: _kDivider),
                  itemBuilder: (_, i) {
                    final pt = filtered[i];
                    final sel = widget.localRetirada == pt;
                    return Material(
                      color: sel ? _kGreenPill : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        leading: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: sel ? AppColors.primary : AppColors.outline,
                        ),
                        title: Text(
                          pt,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel
                                ? AppColors.primary
                                : AppColors.onSurface,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 16)
                            : null,
                        onTap: () => widget.onLocalSelected(pt),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LogisticCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LogisticCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Colors.white : _kInputBg,
          borderRadius: BorderRadius.circular(12),
          border:
              selected ? Border.all(color: _kSelBorder, width: 2) : null,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? Colors.white : _kInputBg,
                borderRadius: BorderRadius.circular(6),
                border: selected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: AppColors.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
