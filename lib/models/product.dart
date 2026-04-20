class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String categoryId;
  final List<String> imageUrls;
  final String location;
  final double? shippingCost;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.categoryId,
    required this.imageUrls,
    required this.location,
    this.shippingCost,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      categoryId: map['categoryId'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      location: map['location'] ?? '',
      shippingCost: map['shippingCost'] != null ? (map['shippingCost']).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'categoryId': categoryId,
      'imageUrls': imageUrls,
      'location': location,
      if (shippingCost != null) 'shippingCost': shippingCost,
    };
  }
}
