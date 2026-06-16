import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../shared/widgets/status_badge.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final ordersAsync = ref.watch(ordersStreamProvider);
    final discountsAsync = ref.watch(discountsStreamProvider);
    final usersMapAsync = ref.watch(usersMapProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Orders',
                  value: ordersAsync.when(
                    data: (orders) => orders
                        .where((o) => o.status.toLowerCase() != 'pending')
                        .length
                        .toString(),
                    loading: () => '...',
                    error: (error, stackTrace) => 'Error',
                  ),
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => context.go('/orders'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  title: 'Products',
                  value: productsAsync.when(
                    data: (products) => products.length.toString(),
                    loading: () => '...',
                    error: (error, stackTrace) => 'Error',
                  ),
                  icon: Icons.inventory_2_outlined,
                  onTap: () => context.go('/products'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  title: 'Active Coupons',
                  value: discountsAsync.when(
                    data: (discounts) =>
                        discounts.where((d) => d.active).length.toString(),
                    loading: () => '...',
                    error: (error, stackTrace) => 'Error',
                  ),
                  icon: Icons.confirmation_num_outlined,
                  onTap: () => context.go('/discounts'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ordersAsync.when(
              data: (orders) {
                final recentTop5 = orders
                    .where((o) => o.status.toLowerCase() != 'pending')
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final top5 = recentTop5.take(5).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top5.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = top5[index];
                    final userData = usersMapAsync.asData?.value[order.userId];
                    final displayName = (userData?['displayName'] as String?)?.trim() ?? order.userName;
                    return ListTile(
                      title: Text(displayName),
                      subtitle: Text(order.id),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusBadge.fromOrderStatus(order.status),
                          const SizedBox(height: 6),
                          Text(
                            'KES ${order.totalPrice}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      onTap: () => context.go('/orders'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => const Center(child: Text('Error loading recent orders')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);

    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.primary;
    final iconBg = colorScheme.primaryContainer;

    final card = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: card,
    );
  }
}
