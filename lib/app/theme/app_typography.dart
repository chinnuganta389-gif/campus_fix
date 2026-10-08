import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized typography rules for CampusFix V2
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';

  // Display Styles
  static TextStyle displayLarge(bool isDark) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.2,
      );

  static TextStyle displayMedium(bool isDark) => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.25,
      );

  // Headline Styles
  static TextStyle headlineLarge(bool isDark) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.3,
      );

  static TextStyle headlineMedium(bool isDark) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.35,
      );

  // Title Styles
  static TextStyle titleMedium(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.4,
      );

  static TextStyle titleSmall(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.4,
      );

  // Body Styles
  static TextStyle bodyLarge(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.5,
      );

  static TextStyle bodyMedium(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        height: 1.5,
      );

  static TextStyle bodySmall(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        height: 1.4,
      );

  // Label & Action Styles
  static TextStyle labelLarge(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle labelMedium(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle labelSmall(bool isDark) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      );
}
