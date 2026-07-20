import 'package:flutter/material.dart';
import 'package:spdms_app/core/theme/app_colors.dart';

class SharedProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final double radius;

  const SharedProfileHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.person,
    this.radius = 50,
  });

  @override
  Widget build(BuildContext context) {
    // Use the calling context's theme primaryColor if available,
    // otherwise fall back to AppColors.darkSlate.
    final color = Theme.of(context).primaryColor;
    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            icon,
            size: radius,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
