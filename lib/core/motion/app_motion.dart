import 'package:flutter/material.dart';

/// Centralized motion design tokens and accessibility helpers for CampusFix.
/// Inspired by high-end cinematic interaction physics (decelerated cubic curves,
/// disciplined micro-press feedback, and zero unnecessary bounce).
class AppMotion {
  AppMotion._();

  // ==========================================
  // DURATIONS
  // ==========================================
  /// Instant micro-feedback (e.g. press scale down, hover highlight)
  static const Duration durationFast = Duration(milliseconds: 140);

  /// Standard component micro-interaction (e.g. chip toggle, tab switch)
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// Moderate card reveals and modal transitions
  static const Duration durationMedium = Duration(milliseconds: 380);

  /// Page entrance and staggered hero reveals
  static const Duration durationPage = Duration(milliseconds: 500);

  /// Cinematic hero and status lifecycle progressions
  static const Duration durationCinematic = Duration(milliseconds: 700);

  /// KPI counter number rollup duration
  static const Duration durationCounter = Duration(milliseconds: 900);

  /// Ambient idle loop (floating icons, breathing indicators)
  static const Duration durationAmbient = Duration(milliseconds: 2800);

  // ==========================================
  // EASING CURVES
  // ==========================================
  /// Primary cinematic curve: smooth, elegant deceleration with no harsh rebound
  static const Curve curveCinematic = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Smooth ease out for entrance transitions
  static const Curve curveDecelerate = Curves.easeOutCubic;

  /// Symmetrical easing for micro-press and hover
  static const Curve curveMicro = Curves.easeInOutCubic;

  /// Subtle responsive spring for confirmation checkmarks and badges
  static const Curve curveSpring = Curves.easeOutBack;

  /// Linear curve for ambient continuous shimmers
  static const Curve curveLinear = Curves.linear;

  // ==========================================
  // ACCESSIBILITY & UTILITIES
  // ==========================================
  /// Returns whether the user's system preferences request reduced motion
  /// or if executing in an automated testing environment.
  static bool isReducedMotion([BuildContext? context]) {
    if (context != null) {
      final mq = MediaQuery.maybeOf(context);
      if (mq != null && mq.disableAnimations) {
        return true;
      }
    }
    // Also detect automated test environment to settle pumpAndSettle cleanly
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('Test');
  }

  /// Returns adjusted duration respecting accessibility settings.
  static Duration getDuration(BuildContext context, Duration standard) {
    if (isReducedMotion(context)) {
      return Duration.zero;
    }
    return standard;
  }
}
