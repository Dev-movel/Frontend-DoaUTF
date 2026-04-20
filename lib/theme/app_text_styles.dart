import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
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
}
