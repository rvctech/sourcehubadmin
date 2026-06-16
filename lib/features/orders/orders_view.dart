import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../core/theme.dart' show AppTheme;
import '../shared/widgets/filter_button.dart';
import '../shared/widgets/status_badge.dart';
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

  Future<void> _showOrderDetails(OrderModel order, List<Product> products) async {
    final userData = await ref.read(firestoreServiceProvider).getUserData(order.userId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(
        order: order,
        products: products,
        userName: userData?['displayName'] as String?,
        userEmail: userData?['email'] as String?,
        userPhone: userData?['phoneNumber'] as String?,
        userAddress: userData?['address'] as String?,
        onUpdateStatus: (newStatus) async {
          await ref.read(firestoreServiceProvider).updateOrderStatus(order.id, newStatus);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final usersMapAsync = ref.watch(usersMapProvider);

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
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilterButton(
                label: 'Date',
                isActive: _sortBy == 'date',
                onTap: () => setState(() => _sortBy = 'date'),
              ),
              const SizedBox(width: 8),
              FilterButton(
                label: 'Status',
                isActive: _sortBy == 'status',
                onTap: () => setState(() => _sortBy = 'status'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: ClipRect(
                child: productsAsync.when(
                  data: (products) {
                    return ordersAsync.when(
                      data: (orders) {
                        final usersMap = usersMapAsync.asData?.value ?? {};
                        final filteredOrders = orders.where((o) {
                          final u = usersMap[o.userId];
                          final name = (u?['displayName'] as String?)?.toLowerCase() ?? o.userName.toLowerCase();
                          final email = (u?['email'] as String?)?.toLowerCase() ?? o.userEmail.toLowerCase();
                          final matchesSearch = o.id.toLowerCase().contains(_searchQuery) ||
                              name.contains(_searchQuery) ||
                              email.contains(_searchQuery);
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
                        return _buildOrdersTable(filteredOrders, products, usersMapAsync);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(List<OrderModel> orders, List<Product> products, AsyncValue<Map<String, Map<String, dynamic>>> usersMapAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.withValues(alpha: 0.05)),
        horizontalMargin: 12,
        columnSpacing: 12,
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
          final userData = usersMapAsync.asData?.value[order.userId];
          final displayName = (userData?['displayName'] as String?)?.trim();
          final displayEmail = (userData?['email'] as String?)?.trim();

          return DataRow(
            cells: [
              DataCell(Text(
                order.id.length > 8 ? '${order.id.substring(0, 8)}...' : order.id,
              )),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr),
                  Text(timeStr, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              )),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName ?? order.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    displayEmail ?? order.userEmail,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              )),
              DataCell(Text(
                'KES ${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(StatusBadge.fromOrderStatus(order.status)),
              DataCell(OutlinedButton.icon(
                onPressed: () => _showOrderDetails(order, products),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                  foregroundColor: AppTheme.primarySeedColor,
                ),
              )),
            ],
          );
        }).toList(),
        ),
      ),
    );
  }

}
