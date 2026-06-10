import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../models/order.dart';
import '../../../../models/product.dart';

class OrderDetailsDialog extends StatefulWidget {
  final OrderModel order;
  final List<Product> products;
  final Future<void> Function(String status) onUpdateStatus;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.products,
    required this.onUpdateStatus,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    final subtotal =
        widget.order.items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final shippingByProductId = {
      for (final p in widget.products) p.id: p.shippingCost ?? 0,
    };
    final deliveryFee = widget.order.items.fold<double>(
      0,
      (sum, item) => sum + (shippingByProductId[item.productId] ?? 0) * item.quantity,
    );
    final total = widget.order.totalPrice;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Order #${widget.order.id.substring(0, 8)}'),
          _StatusDropdown(
            currentStatus: _selectedStatus,
            onChanged: (val) async {
              final newStatus = val;
              if (newStatus == null) return;

              final prevStatus = _selectedStatus;

              setState(() => _selectedStatus = newStatus);

              try {
                // Ensure the Firestore update completes; UI already updated locally.
                await widget.onUpdateStatus(newStatus);
              } catch (_) {
                // Revert UI if Firestore update fails.
                if (mounted) setState(() => _selectedStatus = prevStatus);
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCustomerInfo(),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 3,
                    child: _buildOrderItems(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildSummary(subtotal, deliveryFee, total),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _InfoRow(label: 'Name', value: widget.order.userName),
        _InfoRow(label: 'Email', value: widget.order.userEmail),
        _InfoRow(label: 'Phone', value: widget.order.userPhone),
        _InfoRow(label: 'Address', value: widget.order.userAddress),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      image: item.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(item.imageUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${item.quantity} x KES ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'KES ${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildSummary(double subtotal, double deliveryFee, double total) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 300,
        child: Column(
          children: [
            _SummaryRow(label: 'Subtotal', value: subtotal),
            _SummaryRow(label: 'Delivery Fee', value: deliveryFee),
            if (widget.order.discountAmount > 0)
              _SummaryRow(
                label: 'Discount (${widget.order.discountCode})',
                value: -widget.order.discountAmount,
                color: Colors.red,
              ),
            const Divider(),
            _SummaryRow(label: 'Total', value: total, isBold: true, fontSize: 18),
          ],
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({required this.currentStatus, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statuses = ['confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statuses.contains(currentStatus.toLowerCase())
              ? currentStatus.toLowerCase()
              : 'pending',
          items: statuses
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'KES ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
