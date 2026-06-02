import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userAddress;
  final double totalPrice;
  final double shippingCost;
  final String status;
  final List<OrderItem> items;
  final String? discountCode;
  final double discountAmount;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userAddress,
    required this.totalPrice,
    required this.shippingCost,
    required this.status,
    required this.items,
    this.discountCode,
    this.discountAmount = 0,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? map['customerName'] ?? 'Unknown',
      userEmail: map['userEmail'] ?? map['customerEmail'] ?? 'N/A',
      userPhone: map['userPhone'] ?? map['customerPhone'] ?? 'N/A',
      userAddress: map['userAddress'] ?? map['shippingAddress'] ?? 'N/A',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      shippingCost: (map['shippingCost'] ?? map['shipping_cost'] ?? 0)
          .toDouble(),
      status: map['status'] ?? 'pending',
      items: List<OrderItem>.from(
        (map['items'] ?? []).map((x) => OrderItem.fromMap(x)),
      ),
      discountCode: map['discountCode'],
      discountAmount: (map['discountAmount'] ?? map['discount'] ?? 0)
          .toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userAddress': userAddress,
      'totalPrice': totalPrice,
      'shippingCost': shippingCost,
      'status': status,
      'items': items.map((x) => x.toMap()).toList(),
      'discountCode': discountCode,
      'discountAmount': discountAmount,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final List<String> imageUrls;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrls,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? map['qty'] ?? 1).toInt(),
      imageUrls: List<String>.from(
        map['imageUrls'] ?? (map['product']?['imageUrls'] ?? []),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrls': imageUrls,
    };
  }
}
