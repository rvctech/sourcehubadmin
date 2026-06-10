import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../models/product.dart';

class ProductsTable extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onEdit;
  final void Function(String) onDelete;
  final void Function(BuildContext, String) onImageTap;

  const ProductsTable({
    super.key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.withValues(alpha: 0.05)),
          horizontalMargin: 12,
          columnSpacing: 12,
          columns: const [
            DataColumn(label: Text('Image')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Featured')),
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
                              .map((url) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: InkWell(
                                      onTap: () => onImageTap(context, url),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: CachedNetworkImage(
                                          imageUrl: url,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        )
                      : const Text('No images', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                DataCell(SizedBox(
                  width: 200,
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Icon(
                  product.featured ? Icons.star : Icons.star_border,
                  color: product.featured ? Colors.amber : Colors.grey,
                  size: 20,
                )),
                DataCell(Text('KES ${product.price.toStringAsFixed(2)}')),
                DataCell(_buildQuantityBadge(product.quantity)),
                DataCell(Text(product.location)),
                DataCell(Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onEdit(product),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => onDelete(product.id),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                )),
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
          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
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
          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$quantity In Stock',
          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}
