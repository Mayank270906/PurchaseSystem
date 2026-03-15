/// Purchase model

class Purchase {
  final int id;
  final int vendorId;
  final String? vendorName;
  final int itemId;
  final String? itemName;
  final double quantity;
  final String datetime;
  final String? recordedBy;
  final double? unitPrice;
  final double? totalAmount;

  Purchase({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.itemId,
    this.itemName,
    required this.quantity,
    required this.datetime,
    this.recordedBy,
    this.unitPrice,
    this.totalAmount,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      quantity: double.parse(json['quantity'].toString()),
      datetime: json['datetime'],
      recordedBy: json['recorded_by'],
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : null,
      totalAmount: json['total_amount'] != null
          ? double.parse(json['total_amount'].toString())
          : null,
    );
  }
}
