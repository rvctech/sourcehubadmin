import 'package:flutter/material.dart';

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
        backgroundColor: isActive ? const Color(0xFF1A73E8) : Colors.transparent,
        side: BorderSide(
          color: isActive ? const Color(0xFF1A73E8) : Colors.black.withValues(alpha: 0.06),
        ),
        foregroundColor: isActive ? Colors.white : const Color(0xFF7B7F86),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
