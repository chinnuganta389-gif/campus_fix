import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../widgets/custom_button.dart';
import 'app_motion.dart';
import 'motion_reveal.dart';

/// Animated Empty State featuring gentle ambient floating motion and staggered entrance
class AnimatedEmptyState extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AnimatedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    final isReduced = AppMotion.isReducedMotion();
    _floatController = AnimationController(
      vsync: this,
      duration: AppMotion.durationAmbient,
    );

    if (!isReduced) {
      _floatController.repeat(reverse: true);
    }

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReduced = AppMotion.isReducedMotion(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating Ambient Icon
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                final y = isReduced ? 0.0 : _floatAnimation.value;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: isReduced ? 0.1 : (0.12 + (_floatAnimation.value + 6) / 100),
                          ),
                          blurRadius: isReduced ? 16 : (20 + _floatAnimation.value),
                          offset: Offset(0, isReduced ? 8 : (12 - _floatAnimation.value)),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 48,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            MotionReveal(
              delay: const Duration(milliseconds: 100),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            MotionReveal(
              delay: const Duration(milliseconds: 180),
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.buttonText != null && widget.onButtonPressed != null) ...[
              const SizedBox(height: 24),
              MotionReveal(
                delay: const Duration(milliseconds: 260),
                child: CustomButton(
                  text: widget.buttonText!,
                  width: 190,
                  height: 44,
                  onPressed: widget.onButtonPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated Error State featuring subtle alert pulse and smooth retry action
class AnimatedErrorState extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AnimatedErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  State<AnimatedErrorState> createState() => _AnimatedErrorStateState();
}

class _AnimatedErrorStateState extends State<AnimatedErrorState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.96), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _pulseController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 44,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Load',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 22),
              CustomButton(
                text: 'Try Again',
                icon: Icons.refresh_rounded,
                width: 150,
                height: 42,
                variant: ButtonVariant.outline,
                onPressed: () {
                  _pulseController.forward(from: 0.0);
                  widget.onRetry?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated Success State for complaint submission confirmation
class AnimatedSuccessView extends StatefulWidget {
  final String complaintId;
  final String title;
  final VoidCallback onViewComplaint;
  final VoidCallback onDone;

  const AnimatedSuccessView({
    super.key,
    required this.complaintId,
    required this.title,
    required this.onViewComplaint,
    required this.onDone,
  });

  @override
  State<AnimatedSuccessView> createState() => _AnimatedSuccessViewState();
}

class _AnimatedSuccessViewState extends State<AnimatedSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScaleAnimation;
  late final Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _checkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _ringAnimation = Tween<double>(begin: 0.2, end: 1.35).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark with expanding ring
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding ring
                      Opacity(
                        opacity: (1.0 - (_controller.value * 0.9)).clamp(0.0, 1.0),
                        child: Container(
                          width: 80 * _ringAnimation.value,
                          height: 80 * _ringAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      // Core checkmark badge
                      ScaleTransition(
                        scale: _checkScaleAnimation,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x4010B981),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              MotionReveal(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Complaint Submitted!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              MotionReveal(
                delay: const Duration(milliseconds: 380),
                child: Text(
                  'Your ticket has been logged and queued for facility administration dispatch.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Ticket ID badge
              MotionReveal(
                delay: const Duration(milliseconds: 460),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ticket ID: ${widget.complaintId}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              MotionReveal(
                delay: const Duration(milliseconds: 540),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Track Ticket',
                        icon: Icons.visibility_outlined,
                        variant: ButtonVariant.primary,
                        height: 48,
                        onPressed: widget.onViewComplaint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Done',
                        variant: ButtonVariant.outline,
                        height: 48,
                        onPressed: widget.onDone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
