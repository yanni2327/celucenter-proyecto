import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display / Syne ─────────────────────────────────────────────────────────
  static TextStyle heroTitle({double fontSize = 44}) => GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        height: 1.05,
        letterSpacing: -1.5,
      );

  static TextStyle sectionTitle({double fontSize = 24}) => GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
        letterSpacing: -0.5,
      );

  static TextStyle productPrice({double fontSize = 18}) => GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle statNumber({double fontSize = 22}) => GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      );

  static TextStyle logoText({double fontSize = 18}) => GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColors.dark,
        letterSpacing: -0.5,
      );

  static TextStyle promoTitle({double fontSize = 28}) => GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: -0.8,
        height: 1.1,
      );

  // ── Cuerpo / DM Sans ───────────────────────────────────────────────────────
  static TextStyle body({
    double fontSize = 14,
    Color color = AppColors.dark,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  static TextStyle navLink() => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF555555),
      );

  static TextStyle productName() => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.dark,
        height: 1.3,
      );

  static TextStyle brandLabel() => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.midGray,
        letterSpacing: 0.8,
      );

  static TextStyle catName() => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF333333),
      );

  static TextStyle catCount() => GoogleFonts.dmSans(
        fontSize: 11,
        color: AppColors.midGray,
      );

  static TextStyle statLabel() => GoogleFonts.dmSans(
        fontSize: 11,
        color: const Color(0xFF666666),
        letterSpacing: 0.3,
      );

  static TextStyle footerLink() => GoogleFonts.dmSans(
        fontSize: 12,
        color: const Color(0xFF888888),
      );

  static TextStyle footerCopy() => GoogleFonts.dmSans(
        fontSize: 11,
        color: const Color(0xFFBBBBBB),
      );

  static TextStyle badge({Color color = AppColors.white}) =>
      GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle btnLabel({double fontSize = 14}) => GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      );

  static TextStyle heroTag() => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.g5,
      );

  static TextStyle heroSub() => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFAAAAAA),
        height: 1.6,
      );

  static TextStyle oldPrice() => GoogleFonts.dmSans(
        fontSize: 11,
        color: const Color(0xFFBBBBBB),
        decoration: TextDecoration.lineThrough,
      );
}
