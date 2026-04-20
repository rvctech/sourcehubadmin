import 'package:flutter/material.dart';
import '../../../../models/order.dart';

class OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;
  final Function(String status) onUpdateStatus;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = order.items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final deliveryFee = 200.0; // Placeholder or from order logic
    final total = order.totalPrice;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Order #${order.id.substring(0, 8)}'),
          _StatusDropdown(
            currentStatus: order.status,
            onChanged: (val) {
              if (val != null) onUpdateStatus(val);
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
        _InfoRow(label: 'Name', value: order.userName),
        _InfoRow(label: 'Email', value: order.userEmail),
        _InfoRow(label: 'Phone', value: order.userPhone),
        _InfoRow(label: 'Address', value: order.userAddress),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...order.items.map((item) => Padding(
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
                          image: NetworkImage(item.imageUrls.first),
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
                    Text('${item.quantity} x KES ${item.price.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text('KES ${(item.price * item.quantity).toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
            if (order.discountAmount > 0)
              _SummaryRow(label: 'Discount (${order.discountCode})', value: -order.discountAmount, color: Colors.red),
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
    final statuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statuses.contains(currentStatus.toLowerCase()) ? currentStatus.toLowerCase() : 'pending',
          items: statuses.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
          )).toList(),
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
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
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
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
