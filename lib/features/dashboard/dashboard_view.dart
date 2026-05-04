import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/services/providers.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final ordersAsync = ref.watch(ordersStreamProvider);
    final discountsAsync = ref.watch(discountsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Revenue',
                  value: ordersAsync.when(
                    data: (orders) {
                      final total = orders
                          .where((o) => o.status == 'delivered')
                          .fold<double>(0, (sum, item) => sum + item.totalPrice);
                      return 'KES ${total.toStringAsFixed(0)}';
                    },
                    loading: () => '...',
                    error: (error, stackTrace) => 'Error',
                  ),
                  icon: Icons.payments_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  title: 'Orders',
                  value: ordersAsync.when(
                    data: (orders) => orders.where((o) => o.status.toLowerCase() != 'pending').length.toString(),
                    loading: () => '...',
                    error: (error, stackTrace) => 'Error',
                  ),
                  icon: Icons.shopping_cart_outlined,
                  color: Colors.blue,
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
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _StatCard(
                  title: 'Active Coupons',
                  value: discountsAsync.when(
                    data: (discounts) => discounts.where((d) => d.active).length.toString(),
                    loading: () => '...',
                    error: (error, stackTrace) => 'Error',
                  ),
                  icon: Icons.confirmation_num_outlined,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Text(
            'Recent Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ordersAsync.when(
              data: (orders) {
                final recent = orders.where((o) => o.status.toLowerCase() != 'pending').take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = recent[index];
                    return ListTile(
                      title: Text(order.userName),
                      subtitle: Text(order.id),
                      trailing: Text('KES ${order.totalPrice}'),
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
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7B7F86),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
