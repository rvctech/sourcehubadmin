import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../models/order.dart';
import '../../../../models/product.dart';

class OrderDetailsDialog extends StatefulWidget {
  final OrderModel order;
  final List<Product> products;
  final Future<void> Function(String status) onUpdateStatus;
  final Future<void> Function()? onMarkShippingCollected;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userAddress;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    required this.products,
    required this.onUpdateStatus,
    this.onMarkShippingCollected,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userAddress,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  late String _selectedStatus;
  bool _isMarkingCollected = false;

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
              if (widget.order.shippingPaymentMethod == 'on_delivery' && !widget.order.shippingCollected)
                _buildShippingDueBanner(),
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

  String get _displayName => (widget.order.userName.isNotEmpty && widget.order.userName != 'N/A') ? widget.order.userName : (widget.userName ?? 'N/A');
  String get _displayEmail => widget.order.userEmail != 'N/A' ? widget.order.userEmail : (widget.userEmail ?? 'N/A');
  String get _displayPhone => widget.order.userPhone != 'N/A' ? widget.order.userPhone : (widget.userPhone ?? 'N/A');
  String get _displayAddress => widget.order.userAddress != 'N/A' ? widget.order.userAddress : (widget.userAddress ?? 'N/A');

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _InfoRow(label: 'Name', value: _displayName),
        _InfoRow(label: 'Email', value: _displayEmail),
        _InfoRow(label: 'Phone', value: _displayPhone),
        _InfoRow(label: 'Address', value: _displayAddress),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...widget.order.items.map((item) {
          final product = widget.products.where((p) => p.id == item.productId).firstOrNull;
          final imageUrl = item.imageUrls.isNotEmpty
              ? item.imageUrls.first
              : (product?.imageUrls.isNotEmpty == true ? product!.imageUrls.first : null);
          return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(imageUrl),
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
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            );
          }),
      ],
    );
  }

  Widget _buildSummary(double subtotal, double deliveryFee, double total) {
    final amountPaid = widget.order.amountPaid;
    final dueOnDelivery = total - amountPaid;

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
                color: Theme.of(context).colorScheme.error,
              ),
            const Divider(),
            _SummaryRow(label: 'Total', value: total, isBold: true, fontSize: 18),
            _SummaryRow(label: 'Amount Paid', value: amountPaid, color: Colors.green),
            if (widget.order.shippingPaymentMethod == 'on_delivery' && !widget.order.shippingCollected && dueOnDelivery > 0)
              _SummaryRow(
                label: 'Due on Delivery',
                value: dueOnDelivery,
                color: Colors.amber.shade800,
                isBold: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDueBanner() {
    final dueOnDelivery = widget.order.totalPrice - widget.order.amountPaid;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Payment Due on Delivery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'KES ${dueOnDelivery.toStringAsFixed(2)} to be collected upon delivery.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onMarkShippingCollected != null && !_isMarkingCollected)
            TextButton.icon(
              onPressed: () async {
                setState(() => _isMarkingCollected = true);
                try {
                  await widget.onMarkShippingCollected!();
                  if (mounted) setState(() => _isMarkingCollected = false);
                } catch (_) {
                  if (mounted) setState(() => _isMarkingCollected = false);
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Mark Collected'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          if (_isMarkingCollected)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
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
