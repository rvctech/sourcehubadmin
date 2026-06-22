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
    final map = product.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('products').add(map);
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

  Stream<Map<String, Map<String, dynamic>>> getAllUsersStream() {
    return _db.collection('users').snapshots().map((snapshot) {
      final map = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        map[doc.id] = doc.data();
      }
      return map;
    });
  }

  // --- Orders ---
  Stream<List<OrderModel>> getOrders() {
    return _db
        .collection('orders')
        .where('status', isNotEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<OrderModel>> getOrdersByPaymentGroupId(String paymentGroupId) async {
    final snapshot = await _db
        .collection('orders')
        .where('paymentGroupId', isEqualTo: paymentGroupId)
        .where('status', isNotEqualTo: 'pending')
        .get();
    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> markShippingCollected(String orderId, String adminUid) async {
    await _db.collection('orders').doc(orderId).update({
      'shippingCollected': true,
      'shippingCollectedAt': FieldValue.serverTimestamp(),
      'shippingCollectedBy': adminUid,
    });
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
