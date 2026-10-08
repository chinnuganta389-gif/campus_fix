import 'package:flutter/material.dart';
import 'app_motion.dart';

/// An animated integer counter that rolls up smoothly from 0 to its target value
/// using cinematic easing.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.durationCounter,
    this.curve = AppMotion.curveCinematic,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return Text(
        '$prefix$value$suffix',
        style: style,
      );
    }

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, currentValue, child) {
        return Text(
          '$prefix$currentValue$suffix',
          style: style,
        );
      },
    );
  }
}
