/// Vendor item price model

class VendorPrice {
  final int id;
  final int itemId;
  final String itemName;
  final String? description;
  final double price;
  final String? updatedAt;
  final String? updatedBy;

  VendorPrice({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.description,
    required this.price,
    this.updatedAt,
    this.updatedBy,
  });

  factory VendorPrice.fromJson(Map<String, dynamic> json) {
    return VendorPrice(
      id: json['id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      updatedAt: json['updated_at'],
      updatedBy: json['updated_by'],
    );
  }
}
