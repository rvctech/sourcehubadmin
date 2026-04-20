import 'package:flutter/material.dart';
import '../../../../models/discount.dart';

class DiscountDialog extends StatefulWidget {
  final Discount? discount;
  final Function(Discount) onSave;

  const DiscountDialog({
    super.key,
    this.discount,
    required this.onSave,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _amountController;
  late TextEditingController _maxUsesController;
  late String _type;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.discount?.code);
    _amountController = TextEditingController(text: widget.discount?.amount.toString());
    _maxUsesController = TextEditingController(
      text: widget.discount?.maxUses != null && widget.discount!.maxUses > 0
          ? widget.discount!.maxUses.toString()
          : '',
    );
    _type = widget.discount?.type ?? 'fixed';
    _active = widget.discount?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.discount != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Discount' : 'Add Discount'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code',
                  hintText: 'e.g. SAVE20',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Discount Amount'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('KES (Fixed)')),
                      DropdownMenuItem(value: 'percentage', child: Text('% (Percent)')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses',
                  hintText: 'e.g. 100',
                  helperText: 'Coupon is automatically disabled after this many uses',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Must be at least 1';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (isEdit) ...[
                const SizedBox(height: 4),
                _buildUsageBar(widget.discount!),
                const SizedBox(height: 8),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Is Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final maxUses = int.parse(_maxUsesController.text);
              final d = Discount(
                id: widget.discount?.id ?? '',
                code: _codeController.text.toUpperCase(),
                amount: double.parse(_amountController.text),
                type: _type,
                uses: widget.discount?.uses ?? 0,
                maxUses: maxUses,
                active: _active,
              );
              widget.onSave(d);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildUsageBar(Discount d) {
    final progress = d.maxUses > 0 ? (d.uses / d.maxUses).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage: ${d.uses} / ${d.maxUses}',
          style: TextStyle(
            fontSize: 12,
            color: progress >= 1.0 ? Colors.red : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          color: progress >= 1.0 ? Colors.red : progress >= 0.8 ? Colors.orange : Colors.green,
        ),
      ],
    );
  }
}
