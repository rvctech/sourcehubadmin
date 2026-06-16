import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/shared/services/firestore_service.dart';
import '../models/category.dart';
import '../models/product.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(firestoreServiceProvider).getProducts();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(firestoreServiceProvider).getCategories();
});

final ordersStreamProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).getOrders();
});

final usersMapProvider = StreamProvider<Map<String, Map<String, dynamic>>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllUsersStream();
});

final discountsStreamProvider = StreamProvider((ref) {
  return ref.watch(firestoreServiceProvider).getDiscounts();
});
