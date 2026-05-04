import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PasswordHint extends StatelessWidget {
  final String password;

  const PasswordHint({super.key, required this.password});

  bool get _hasLength    => password.length >= 8;
  bool get _hasUpperCase => RegExp(r'[A-Z]').hasMatch(password);
  bool get _hasLowerCase => RegExp(r'[a-z]').hasMatch(password);
  bool get _hasNumber    => RegExp(r'[0-9]').hasMatch(password);
  bool get _hasSymbol    =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_+=\[\]\/\\]').hasMatch(password);

  int get _metOptional {
    int count = 0;
    if (_hasUpperCase) count++;
    if (_hasLowerCase) count++;
    if (_hasNumber)    count++;
    if (_hasSymbol)    count++;
    return count;
  }

  bool get _isValid => _hasLength && _metOptional >= 3;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.outline.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isValid
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleRow(label: 'Mínimo de 8 caracteres', met: _hasLength),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.outline.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'precisa de 3 regras adicionais',
                  style: TextStyle(
                    fontSize: 10,
                    color: _metOptional >= 3
                        ? AppColors.primary
                        : AppColors.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.outline.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Regras opcionais
            _RuleRow(label: 'Letra maiúscula (A–Z)', met: _hasUpperCase),
            const SizedBox(height: 4),
            _RuleRow(label: 'Letra minúscula (a–z)', met: _hasLowerCase),
            const SizedBox(height: 4),
            _RuleRow(label: 'Número (0–9)',           met: _hasNumber),
            const SizedBox(height: 4),
            _RuleRow(label: 'Símbolo (!@#...)',        met: _hasSymbol),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RuleRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.primary : AppColors.outline;

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            key: ValueKey(met),
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: met ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}