import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';
import '../../../models/order.dart';
import '../../../models/discount.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Products ---
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // --- Categories ---
  Stream<List<Category>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Category.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addCategory(Category category) async {
    await _db.collection('categories').add(category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    await _db.collection('categories').doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // --- Users ---
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  // --- Orders ---
  Stream<List<OrderModel>> getOrders() {
    return _db
        .collection('orders')
        .where('status', isNotEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      // Collect unique userIds and fetch their profiles
      final userIds = orders.map((o) => o.userId).where((id) => id.isNotEmpty).toSet();
      final userCache = <String, Map<String, dynamic>>{};
      for (final uid in userIds) {
        final userData = await getUserData(uid);
        if (userData != null) {
          userCache[uid] = userData;
        }
      }

      // Enrich orders with user data
      return orders.map((order) {
        final user = userCache[order.userId];
        if (user != null) {
          return OrderModel(
            id: order.id,
            createdAt: order.createdAt,
            userId: order.userId,
            userName: user['displayName'] ?? user['name'] ?? 'Unknown',
            userEmail: user['email'] ?? order.userEmail,
            userPhone: user['phoneNumber'] ?? user['phone'] ?? 'N/A',
            userAddress: user['address'] ?? 'N/A',
            totalPrice: order.totalPrice,
            status: order.status,
            items: order.items,
            discountCode: order.discountCode,
            discountAmount: order.discountAmount,
          );
        }
        return order;
      }).toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  // --- Discounts ---
  Stream<List<Discount>> getDiscounts() {
    return _db.collection('discounts').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Discount.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addDiscount(Discount discount) async {
    await _db.collection('discounts').add(discount.toMap());
  }

  Future<void> updateDiscount(Discount discount) async {
    await _db.collection('discounts').doc(discount.id).update(discount.toMap());
  }

  Future<void> deleteDiscount(String id) async {
    await _db.collection('discounts').doc(id).delete();
  }
}
