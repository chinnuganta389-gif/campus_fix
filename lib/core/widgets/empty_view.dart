import 'package:flutter/material.dart';
import '../motion/animated_state_views.dart';

class EmptyView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      title: title,
      message: message,
      icon: icon,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}
