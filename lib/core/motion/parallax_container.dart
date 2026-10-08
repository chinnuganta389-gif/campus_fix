import 'package:flutter/material.dart';
import 'app_motion.dart';

/// A parallax container that smoothly translates decorative background elements
/// or headers at a decoupled speed relative to scroll position.
class ParallaxContainer extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  final double parallaxFactor; // e.g. 0.2 for slower background shift
  final double maxOffset;

  const ParallaxContainer({
    super.key,
    required this.scrollController,
    required this.child,
    this.parallaxFactor = 0.25,
    this.maxOffset = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return child;
    }

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset = scrollController.hasClients ? scrollController.offset : 0.0;
        final clampedShift = (offset * parallaxFactor).clamp(-maxOffset, maxOffset);
        return Transform.translate(
          offset: Offset(0, -clampedShift),
          child: child,
        );
      },
      child: child,
    );
  }
}
