import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ── Existentes (mantidos idênticos) ────────────────────────────────────────

  static final headline = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );
  static final subtitle = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );
  static final label = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: 1.2,
  );
  static final input = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );
  static final hint = GoogleFonts.manrope(
    fontSize: 14,
    color: AppColors.outline,
  );
  static final button = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0.2,
  );
  static final body = GoogleFonts.manrope(
    fontSize: 13,
    color: AppColors.onSurfaceVariant,
  );
  static final link = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: const Color(0x4D0D631B),
  );
  static final legal = GoogleFonts.manrope(
    fontSize: 10,
    color: AppColors.outline,
    height: 1.6,
  );
  static final sideTitle = GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.onPrimary,
    letterSpacing: -0.5,
  );
  static final sideBody = GoogleFonts.manrope(
    fontSize: 12,
    color: Colors.white70,
    height: 1.5,
  );

  // ── Novos estilos para HomeScreen e cards ───────────────────────────────────

  /// Título hero grande (32–36px)
  static final hero = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.onBackground,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// Títulos de seção (22–24px)
  static final sectionTitle = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.onBackground,
    letterSpacing: -0.3,
  );

  /// Número grande para stat cards (36px)
  static final statValue = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
  );

  /// Label de stat card (11px uppercase)
  static final statLabel = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.8,
  );

  /// Título de card de item (18px)
  static final cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
  );

  /// Título de feature card (16px)
  static final featureTitle = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
  );

  /// Badge pequeno em capsule (9px uppercase)
  static final badge = GoogleFonts.manrope(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0.8,
  );

  /// Texto de CTA grande (16px bold on primary container)
  static final ctaTitle = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.onPrimaryContainer,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// Rótulo de seção curada (10px uppercase verde)
  static final sectionTag = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.2,
  );
}