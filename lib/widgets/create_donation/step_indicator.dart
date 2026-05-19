import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

const _kInputBg   = Color(0xFFE3E3DE);
const _kDivider   = Color(0x4DBFCABA);
const _kGreenPill = Color(0x1A2E7D32);

class DonationStepIndicator extends StatelessWidget {
  final int currentStep;
  const DonationStepIndicator({super.key, required this.currentStep});

  static const _labels = ['Detalhes', 'Fotos', 'Logística'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _labels.length; i++) ...[
          _StepPill(
            index: i,
            label: _labels[i],
            isActive: i == currentStep,
            isDone: i < currentStep,
          ),
          if (i < _labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < currentStep ? AppColors.primary : _kDivider,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepPill({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isActive || isDone ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _kGreenPill : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive || isDone ? AppColors.primary : _kInputBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
