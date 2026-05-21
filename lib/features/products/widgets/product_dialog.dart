import 'package:flutter/material.dart';
import '../../../../models/product.dart';
import '../../../../models/category.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final Function(Product) onSave;

  const ProductDialog({
    super.key,
    this.product,
    required this.categories,
    required this.onSave,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _locationController;
  late TextEditingController _shippingController;
  late TextEditingController _imageUrlsController;
  String? _selectedCategoryId;
  bool _featured = false;

  String _formatDouble(double? value) {
    if (value == null) return '';
    return value == value.truncateToDouble() 
        ? value.toInt().toString() 
        : value.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name);
    _descController = TextEditingController(text: p?.description);
    _priceController = TextEditingController(text: _formatDouble(p?.price));
    _qtyController = TextEditingController(text: p?.quantity.toString());
    _locationController = TextEditingController(text: p?.location);
    _shippingController = TextEditingController(text: _formatDouble(p?.shippingCost));
    _imageUrlsController = TextEditingController(text: p?.imageUrls.join(', '));
    _selectedCategoryId = (p?.categoryId != null && p!.categoryId.isNotEmpty)
        ? p.categoryId
        : (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _featured = p?.featured ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _locationController.dispose();
    _shippingController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price (KES)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories.map((c) => 
                    DropdownMenuItem(value: c.id, child: Text(c.name))
                  ).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlsController,
                  decoration: const InputDecoration(
                    labelText: 'Image URLs (comma separated)',
                    hintText: 'https://..., https://...',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shippingController,
                  decoration: const InputDecoration(labelText: 'Shipping Cost (Optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Featured'),
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final product = Product(
                id: widget.product != null ? widget.product!.id : '',
                name: _nameController.text,
                description: _descController.text,
                price: double.parse(_priceController.text),
                quantity: int.parse(_qtyController.text),
                categoryId: _selectedCategoryId ?? '',
                imageUrls: _imageUrlsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                location: _locationController.text,
                shippingCost: double.tryParse(_shippingController.text),
                featured: _featured,
              );
              widget.onSave(product);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
