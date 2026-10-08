import 'package:flutter/material.dart';
import '../motion/animated_state_views.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedErrorState(
      message: message,
      onRetry: onRetry,
      icon: icon,
    );
  }
}
