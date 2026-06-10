import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? AppTheme.primarySeedColor : Colors.transparent,
        side: BorderSide(
          color: isActive ? AppTheme.primarySeedColor : Colors.black.withValues(alpha: 0.06),
        ),
        foregroundColor: isActive ? Colors.white : AppTheme.mutedColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
