import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// FAB estendido com gradiente da marca.
class GradientFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const GradientFab({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.subtleBrandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusM + 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
