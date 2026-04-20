class Discount {
  final String id;
  final String code;
  final double amount;
  final String type; // 'fixed' or 'percentage'
  final int uses;
  final int maxUses;
  final bool active;

  Discount({
    required this.id,
    required this.code,
    required this.amount,
    required this.type,
    required this.uses,
    required this.maxUses,
    required this.active,
  });

  /// Whether this coupon can still be redeemed
  bool get isUsable => active && uses < maxUses;

  factory Discount.fromMap(Map<String, dynamic> map, String id) {
    return Discount(
      id: id,
      code: map['code'] ?? '',
      amount: (map['amount'] ?? map['discountPercentage'] ?? 0).toDouble(),
      type: map['type'] ?? 'fixed',
      uses: (map['uses'] ?? 0).toInt(),
      maxUses: (map['maxUses'] ?? 0).toInt(),
      active: map['active'] ?? map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'amount': amount,
      'type': type,
      'uses': uses,
      'maxUses': maxUses,
      'active': active,
    };
  }
}
