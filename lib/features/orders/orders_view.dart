import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../shared/services/providers.dart';
import '../../../models/order.dart';
import 'widgets/order_details_dialog.dart';

class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';

  int _statusWeight(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 0;
      case 'processing': return 1;
      case 'shipped': return 2;
      case 'delivered': return 3;
      case 'cancelled': return 4;
      default: return 5;
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(
        order: order,
        onUpdateStatus: (newStatus) async {
          await ref.read(firestoreServiceProvider).updateOrderStatus(order.id, newStatus);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SortButton(
                label: 'Date',
                isActive: _sortBy == 'date',
                onTap: () => setState(() => _sortBy = 'date'),
              ),
              const SizedBox(width: 8),
              _SortButton(
                label: 'Status',
                isActive: _sortBy == 'status',
                onTap: () => setState(() => _sortBy = 'status'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: ordersAsync.when(
                data: (orders) {
                  final filteredOrders = orders.where((o) {
                    final matchesSearch = o.id.toLowerCase().contains(_searchQuery) ||
                        o.userName.toLowerCase().contains(_searchQuery) ||
                        o.userEmail.toLowerCase().contains(_searchQuery);
                    return matchesSearch && o.status.toLowerCase() != 'pending';
                  }).toList()
                    ..sort((a, b) {
                      if (_sortBy == 'status') {
                        return _statusWeight(a.status)
                            .compareTo(_statusWeight(b.status));
                      }
                      return b.createdAt.compareTo(a.createdAt);
                    });

                  if (filteredOrders.isEmpty) {
                    return const Center(child: Text('No orders found'));
                  }
                  return _buildOrdersTable(filteredOrders);
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

  Widget _buildOrdersTable(List<OrderModel> orders) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.withValues(alpha: 0.05)),
          horizontalMargin: 24,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Order ID')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: orders.map((order) {
            final dateStr = DateFormat('MMM d, yyyy').format(order.createdAt);
            final timeStr = DateFormat('HH:mm').format(order.createdAt);

            return DataRow(
              cells: [
                DataCell(Text(order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id)),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr),
                    Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(order.userEmail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
                DataCell(Text('KES ${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(_buildStatusBadge(order.status)),
                DataCell(
                  TextButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed': color = Colors.blue; break;
      case 'processing': color = Colors.orange; break;
      case 'shipped': color = Colors.cyan; break;
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive
            ? const Color(0xFF1A73E8)
            : Colors.transparent,
        side: BorderSide(
          color: isActive
              ? const Color(0xFF1A73E8)
              : Colors.black.withValues(alpha: 0.06),
        ),
        foregroundColor: isActive ? Colors.white : const Color(0xFF7B7F86),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}
