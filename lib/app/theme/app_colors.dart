import 'package:flutter/material.dart';

/// Centralized color palette for CampusFix V2 — LBRCE Campus Operations
/// Follows the official LBRCE + CampusFix design language
class AppColors {
  AppColors._();

  // Primary Brand Colors (LBRCE Navy & Blues)
  static const Color primary = Color(0xFF062B55); // Deep Navy #062B55
  static const Color primaryLight = Color(0xFF1687F7); // Bright Blue #1687F7
  static const Color primaryDark = Color(0xFF041E3D); // Darker Navy
  static const Color primaryContainer = Color(0xFFE8F1FC);

  // Secondary & Accents
  static const Color secondary = Color(0xFF1557C0); // Campus Blue #1557C0
  static const Color secondaryLight = Color(0xFF2970E6);
  static const Color secondaryContainer = Color(0xFFDCE8FA);

  static const Color brightBlue = Color(0xFF1687F7); // Bright Blue #1687F7
  static const Color accent = Color(0xFF20D9D0); // Accent Cyan #20D9D0
  static const Color accentCyan = Color(0xFF20D9D0);
  static const Color accentLight = Color(0xFFE2FAF9);

  // Status Colors
  static const Color success = Color(0xFF16A36A); // #16A36A
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  static const Color warning = Color(0xFFF5A623); // #F5A623
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFD64545); // #D64545
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  static const Color info = Color(0xFF1687F7); // Bright Blue
  static const Color infoContainer = Color(0xFFE0F2FE);

  // Priority Colors
  static const Color priorityLow = Color(0xFF16A36A);
  static const Color priorityMedium = Color(0xFF1557C0);
  static const Color priorityHigh = Color(0xFFF5A623);
  static const Color priorityUrgent = Color(0xFFD64545);

  // Neutral Light (Clean, legible, modern)
  static const Color lightBackground = Color(0xFFF5F8FC); // #F5F8FC
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFEDF2F7);
  static const Color lightTextPrimary = Color(0xFF10233F); // #10233F
  static const Color lightTextSecondary = Color(0xFF6B7C93); // #6B7C93
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Neutral Dark
  static const Color darkBackground = Color(0xFF061526);
  static const Color darkSurface = Color(0xFF0A1F38);
  static const Color darkCard = Color(0xFF0F2B4C);
  static const Color darkBorder = Color(0xFF1A3D66);
  static const Color darkDivider = Color(0xFF153356);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF062B55), Color(0xFF1557C0)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1557C0), Color(0xFF1687F7)],
  );

  static const LinearGradient activeNavGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1557C0), Color(0xFF1687F7)],
  );

  static const LinearGradient heroOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xCC062B55), // 80% opacity Deep Navy
      Color(0xF0061E38), // 94% opacity Deep Navy
    ],
  );

  // Status Badges
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return warning;
      case 'ASSIGNED':
        return secondary;
      case 'IN_PROGRESS':
        return brightBlue;
      case 'RESOLVED':
        return success;
      case 'REJECTED':
      case 'CANCELLED':
        return error;
      default:
        return lightTextSecondary;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return warningContainer;
      case 'ASSIGNED':
        return secondaryContainer;
      case 'IN_PROGRESS':
        return primaryContainer;
      case 'RESOLVED':
        return successContainer;
      case 'REJECTED':
      case 'CANCELLED':
        return errorContainer;
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}
