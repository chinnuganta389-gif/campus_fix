import 'package:flutter/material.dart';
import 'app_motion.dart';

/// A fast, cinematic page transition featuring subtle depth scale,
/// smooth vertical slide (5%), and decoupled fade for professional navigation.
class CinematicPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  CinematicPageRoute({
    required this.child,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 320),
    super.reverseTransitionDuration = const Duration(milliseconds: 260),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (AppMotion.isReducedMotion(context)) {
              return child;
            }

            // Incoming page: fade in + slight slide up + subtle scale
            final curvedIn = CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveCinematic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(0.0, 0.04),
              end: Offset.zero,
            ).animate(curvedIn);

            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curvedIn);

            final scaleIn = Tween<double>(begin: 0.985, end: 1.0).animate(curvedIn);

            // Outgoing underlying page: subtle depth recession
            final curvedOut = CurvedAnimation(
              parent: secondaryAnimation,
              curve: AppMotion.curveCinematic,
            );

            final scaleOut = Tween<double>(begin: 1.0, end: 0.97).animate(curvedOut);
            final fadeOut = Tween<double>(begin: 1.0, end: 0.8).animate(curvedOut);

            return FadeTransition(
              opacity: fadeOut,
              child: ScaleTransition(
                scale: scaleOut,
                child: FadeTransition(
                  opacity: fadeIn,
                  child: SlideTransition(
                    position: slideIn,
                    child: ScaleTransition(
                      scale: scaleIn,
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        );
}
