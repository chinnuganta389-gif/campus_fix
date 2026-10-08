import 'dart:async';
import 'package:flutter/material.dart';
import 'app_motion.dart';

enum RevealDirection { up, down, left, right, none }

/// A smooth, cinematic entrance widget that reveals its child using
/// progressive opacity, directional slide, and subtle scaling.
class MotionReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final RevealDirection direction;
  final double distance;
  final double initialScale;
  final Curve curve;

  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.durationPage,
    this.direction = RevealDirection.up,
    this.distance = 22.0,
    this.initialScale = 0.97,
    this.curve = AppMotion.curveCinematic,
  });

  /// Factory helper for staggered list items
  static Widget staggered({
    required int index,
    required Widget child,
    int baseDelayMs = 40,
    int intervalMs = 60,
    RevealDirection direction = RevealDirection.up,
  }) {
    return MotionReveal(
      delay: Duration(milliseconds: baseDelayMs + (index * intervalMs)),
      direction: direction,
      child: child,
    );
  }

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final isReduced = AppMotion.isReducedMotion();

    _controller = AnimationController(
      vsync: this,
      duration: isReduced ? Duration.zero : widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(curved);

    Offset startOffset;
    switch (widget.direction) {
      case RevealDirection.up:
        startOffset = Offset(0, widget.distance / 100);
        break;
      case RevealDirection.down:
        startOffset = Offset(0, -widget.distance / 100);
        break;
      case RevealDirection.left:
        startOffset = Offset(widget.distance / 100, 0);
        break;
      case RevealDirection.right:
        startOffset = Offset(-widget.distance / 100, 0);
        break;
      case RevealDirection.none:
        startOffset = Offset.zero;
        break;
    }
    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(curved);

    if (isReduced || widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
