/// Product item in the business dashboard (add/delete list).
class BusinessProduct {
  const BusinessProduct({
    required this.id,
    required this.name,
    this.price,
    this.quantity = 0,
  });

  final String id;
  final String name;
  final double? price;
  final int quantity;

  BusinessProduct copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
  }) {
    return BusinessProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
