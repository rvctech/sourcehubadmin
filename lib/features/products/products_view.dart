import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../../models/product.dart';
import '../shared/widgets/confirm_delete_dialog.dart';
import '../shared/widgets/filter_button.dart';
import 'widgets/product_dialog.dart';
import 'widgets/products_table.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  String _filter = 'all';

  void _showProductDialog(BuildContext context, [Product? product]) {
    final pageContext = context;
    showDialog(
      context: context,
      builder: (context) => _ProductDialogWrapper(
        product: product,
        onSave: (savedProduct) async {
          final service = ref.read(firestoreServiceProvider);
          try {
            if (product == null) {
              await service.addProduct(savedProduct);
            } else {
              await service.updateProduct(savedProduct);
            }
            if (pageContext.mounted) {
              ScaffoldMessenger.of(pageContext).showSnackBar(
                SnackBar(
                  content: Text(product == null
                      ? 'Product added successfully'
                      : 'Product updated successfully'),
                ),
              );
            }
          } catch (e) {
            if (pageContext.mounted) {
              ScaffoldMessenger.of(pageContext).showSnackBar(
                SnackBar(
                  content: Text('Failed to ${product == null ? 'add' : 'update'} product: $e'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Product?',
      message: 'This action cannot be undone.',
      onDelete: () => ref.read(firestoreServiceProvider).deleteProduct(productId),
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
              child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
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
                  FilterButton(
                    label: 'All',
                    isActive: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  FilterButton(
                    label: 'Low Stock',
                    isActive: _filter == 'low',
                    onTap: () => setState(() => _filter = 'low'),
                  ),
                  const SizedBox(width: 8),
                  FilterButton(
                    label: 'Out of Stock',
                    isActive: _filter == 'out',
                    onTap: () => setState(() => _filter = 'out'),
                  ),
                  const SizedBox(width: 8),
                  FilterButton(
                    label: 'Featured',
                    isActive: _filter == 'featured',
                    onTap: () => setState(() => _filter = 'featured'),
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
              child: ClipRect(
                child: productsAsync.when(
                  data: (products) {
                    final filteredProducts = _applyFilter(products);
                    if (filteredProducts.isEmpty) {
                      return const Center(child: Text('No products found'));
                    }
                    return ProductsTable(
                      products: filteredProducts,
                      onEdit: (p) => _showProductDialog(context, p),
                      onDelete: (id) => _confirmDelete(context, id),
                      onImageTap: _showImageLightbox,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(' • ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Text('$inStock in stock', style: const TextStyle(color: Colors.green)),
        if (lowStock > 0) ...[
          Text(' • ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(
            '$lowStock low stock',
            style: const TextStyle(color: Colors.orange),
          ),
        ],
        if (outOfStock > 0) ...[
          Text(' • ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
      case 'featured':
        final featured = products.where((p) => p.featured).toList();
        if (featured.isNotEmpty) return featured;
        final sorted = List<Product>.from(products);
        sorted.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return sorted;
      default:
        final sorted = List<Product>.from(products);
        sorted.sort((a, b) {
          if (a.featured && !b.featured) return -1;
          if (!a.featured && b.featured) return 1;
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return sorted;
    }
  }

}

class _ProductDialogWrapper extends ConsumerWidget {
  final Product? product;
  final Future<void> Function(Product) onSave;

  const _ProductDialogWrapper({
    this.product,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) => ProductDialog(
        product: product,
        categories: categories,
        onSave: onSave,
      ),
      loading: () => const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to load categories: $err'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


