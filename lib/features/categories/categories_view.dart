import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../../models/category.dart';
import '../shared/widgets/confirm_delete_dialog.dart';
import 'widgets/category_dialog.dart';

class CategoriesView extends ConsumerWidget {
  const CategoriesView({super.key});

  void _showCategoryDialog(BuildContext context, WidgetRef ref, [Category? category]) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: category,
        onSave: (savedCat) async {
          final service = ref.read(firestoreServiceProvider);
          if (category == null) {
            await service.addCategory(savedCat);
          } else {
            await service.updateCategory(savedCat);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String categoryId) {
    showConfirmDeleteDialog(
      context: context,
      title: 'Delete Category?',
      message: 'This will not delete products in this category, but they will be uncategorized.',
      onDelete: () => ref.read(firestoreServiceProvider).deleteCategory(categoryId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Center(child: Text('No categories found'));
                  }
                  return ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            image: category.imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(category.imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: category.imageUrl.isEmpty ? const Icon(Icons.category) : null,
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(category.imageUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showCategoryDialog(context, ref, category),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context, ref, category.id),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                foregroundColor: Theme.of(context).colorScheme.error,
                                side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
