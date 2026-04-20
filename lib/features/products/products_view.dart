import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/services/providers.dart';
import '../../../models/product.dart';
import 'widgets/product_dialog.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  String _filter = 'all'; // 'all', 'low', 'out'

  void _showProductDialog(BuildContext context, [Product? product]) {
    final categories = ref.read(categoriesStreamProvider).value ?? [];
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        categories: categories,
        onSave: (savedProduct) async {
          final service = ref.read(firestoreServiceProvider);
          if (product == null) {
            await service.addProduct(savedProduct);
          } else {
            await service.updateProduct(savedProduct);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteProduct(productId);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImageLightbox(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  productsAsync.when(
                    data: (products) => _buildStockSummary(products),
                    loading: () => const Text('Loading summary...'),
                    error: (e, s) => const Text('Error loading summary'),
                  ),
                ],
              ),
              Row(
                children: [
                  _FilterButton(
                    label: 'All',
                    isActive: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'Low Stock',
                    isActive: _filter == 'low',
                    onTap: () => setState(() => _filter = 'low'),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: 'Out of Stock',
                    isActive: _filter == 'out',
                    onTap: () => setState(() => _filter = 'out'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showProductDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: productsAsync.when(
                data: (products) {
                  final filteredProducts = _applyFilter(products);
                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }
                  return _buildProductsTable(filteredProducts);
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

  Widget _buildStockSummary(List<Product> products) {
    final total = products.length;
    final outOfStock = products.where((p) => p.quantity == 0).length;
    final lowStock = products
        .where((p) => p.quantity > 0 && p.quantity <= 5)
        .length;
    final inStock = total - outOfStock - lowStock;

    return Row(
      children: [
        Text(
          '$total products',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const Text(' • ', style: TextStyle(color: Colors.grey)),
        Text('$inStock in stock', style: const TextStyle(color: Colors.green)),
        if (lowStock > 0) ...[
          const Text(' • ', style: TextStyle(color: Colors.grey)),
          Text(
            '$lowStock low stock',
            style: const TextStyle(color: Colors.orange),
          ),
        ],
        if (outOfStock > 0) ...[
          const Text(' • ', style: TextStyle(color: Colors.grey)),
          Text(
            '$outOfStock out of stock',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }

  List<Product> _applyFilter(List<Product> products) {
    switch (_filter) {
      case 'low':
        return products
            .where((p) => p.quantity > 0 && p.quantity <= 5)
            .toList();
      case 'out':
        return products.where((p) => p.quantity == 0).toList();
      default:
        return products;
    }
  }

  Widget _buildProductsTable(List<Product> products) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.grey.withValues(alpha: 0.05),
          ),
          horizontalMargin: 24,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Image')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Actions')),
          ],
          rows: products.map((product) {
            Color? rowColor;
            if (product.quantity == 0) {
              rowColor = Colors.red.withValues(alpha: 0.02);
            } else if (product.quantity <= 5) {
              rowColor = Colors.orange.withValues(alpha: 0.02);
            }

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(
                  product.imageUrls.isNotEmpty
                      ? Row(
                          children: product.imageUrls
                              .take(3)
                              .map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: InkWell(
                                    onTap: () =>
                                        _showImageLightbox(context, url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        url,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      : const Text(
                          'No images',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text('KES ${product.price.toStringAsFixed(2)}')),
                DataCell(_buildQuantityBadge(product.quantity)),
                DataCell(Text(product.location)),
                DataCell(
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _showProductDialog(context, product),
                        child: const Text('Edit'),
                      ),
                      TextButton(
                        onPressed: () => _confirmDelete(context, product.id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuantityBadge(int quantity) {
    if (quantity == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (quantity <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$quantity Low Stock',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Text('$quantity');
    }
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
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
