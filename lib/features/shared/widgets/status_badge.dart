import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.fromOrderStatus(String status) {
    final color = switch (status.toLowerCase()) {
      'confirmed' => Colors.blue,
      'processing' => Colors.orange,
      'shipped' => Colors.cyan,
      'delivered' => Colors.green,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return StatusBadge(label: status.toUpperCase(), color: color);
  }

  factory StatusBadge.fromDiscountStatus({required bool expired, required bool active}) {
    if (expired) return const StatusBadge(label: 'EXPIRED', color: Colors.red);
    if (!active) return const StatusBadge(label: 'INACTIVE', color: Colors.grey);
    return const StatusBadge(label: 'ACTIVE', color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
