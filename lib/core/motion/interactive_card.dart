import 'package:flutter/material.dart';
import 'app_motion.dart';

/// A card that responds to hover and press with subtle physics:
/// - Smooth scale compression on press (0.98)
/// - Subtle elevation lift and border glow on hover (desktop/web/tablet)
/// - Clean ripple effect with rounded clipping
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? hoverBorderColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final double hoverElevation;
  final bool enableHover;
  final bool enablePressScale;
  final Clip clipBehavior;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.hoverBorderColor,
    this.borderRadius,
    this.elevation = 0,
    this.hoverElevation = 4,
    this.enableHover = true,
    this.enablePressScale = true,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final isReduced = AppMotion.isReducedMotion(context);

    final baseBg = widget.backgroundColor ??
        (isDark ? theme.colorScheme.surface : theme.cardColor);

    final scale = (widget.enablePressScale && _isPressed && !isReduced) ? 0.98 : 1.0;
    final yOffset = (_isHovered && widget.enableHover && !_isPressed && !isReduced) ? -2.0 : 0.0;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.enableHover) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.enableHover) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTapDown: (_) {
            if (widget.onTap != null && widget.enablePressScale) {
              setState(() => _isPressed = true);
            }
          },
          onTapUp: (_) {
            if (widget.onTap != null && widget.enablePressScale) {
              setState(() => _isPressed = false);
            }
          },
          onTapCancel: () {
            if (widget.enablePressScale) {
              setState(() => _isPressed = false);
            }
          },
          child: AnimatedScale(
            scale: scale,
            duration: AppMotion.durationFast,
            curve: AppMotion.curveMicro,
            child: AnimatedSlide(
              offset: Offset(0, yOffset / 50),
              duration: AppMotion.durationNormal,
              curve: AppMotion.curveDecelerate,
              child: AnimatedContainer(
                duration: AppMotion.durationNormal,
                curve: AppMotion.curveMicro,
                decoration: BoxDecoration(
                  color: baseBg,
                  borderRadius: radius,
                  border: Border.all(
                    color: _isHovered && widget.hoverBorderColor != null
                        ? widget.hoverBorderColor!
                        : (_isHovered
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : theme.colorScheme.primary.withValues(alpha: 0.25))
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05))),
                    width: _isHovered ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.2)
                          : (_isHovered
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.03)),
                      blurRadius: _isHovered ? 16 : 8,
                      offset: Offset(0, _isHovered ? 6 : 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  clipBehavior: widget.clipBehavior,
                  child: InkWell(
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    borderRadius: radius,
                    splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: widget.padding ?? const EdgeInsets.all(16.0),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
