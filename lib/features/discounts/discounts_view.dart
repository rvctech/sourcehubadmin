import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../../models/discount.dart';
import '../shared/widgets/confirm_delete_dialog.dart';
import '../shared/widgets/status_badge.dart';
import 'widgets/discount_dialog.dart';

class DiscountsView extends ConsumerWidget {
  const DiscountsView({super.key});

  void _showDiscountDialog(BuildContext context, WidgetRef ref, [Discount? discount]) {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        discount: discount,
        onSave: (savedD) async {
          final service = ref.read(firestoreServiceProvider);
          if (discount == null) {
            await service.addDiscount(savedD);
          } else {
            await service.updateDiscount(savedD);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Discount?',
      message: 'This will permanently remove this coupon code.',
      onDelete: () => ref.read(firestoreServiceProvider).deleteDiscount(id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountsAsync = ref.watch(discountsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discounts & Coupons',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showDiscountDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New Coupon'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: discountsAsync.when(
                data: (discounts) {
                  if (discounts.isEmpty) {
                    return const Center(child: Text('No discounts found'));
                  }
                  return ListView.separated(
                    itemCount: discounts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = discounts[index];
                      return _DiscountTile(
                        discount: d,
                        onEdit: () => _showDiscountDialog(context, ref, d),
                        onDelete: () => _confirmDelete(context, ref, d.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountTile extends StatelessWidget {
  final Discount discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DiscountTile({
    required this.discount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final d = discount;
    final progress = d.maxUses > 0 ? (d.uses / d.maxUses).clamp(0.0, 1.0) : 0.0;
    final isExpired = d.maxUses > 0 && d.uses >= d.maxUses;
    final progressColor = isExpired
        ? Colors.red
        : progress >= 0.8
            ? Colors.orange
            : Colors.green;

    final statusBadge = StatusBadge.fromDiscountStatus(expired: isExpired, active: d.active);
    final statusColor = isExpired ? Colors.red : d.active ? Colors.green : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Icon
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Icon(Icons.confirmation_num_outlined, color: statusColor),
          ),
          const SizedBox(width: 16),
          // Main info + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      d.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration: isExpired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    statusBadge,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${d.type == 'fixed' ? 'KES ${d.amount.toStringAsFixed(0)}' : '${d.amount.toStringAsFixed(0)}%'} discount',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Usage progress bar
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: progressColor,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${d.uses} / ${d.maxUses} uses',
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
