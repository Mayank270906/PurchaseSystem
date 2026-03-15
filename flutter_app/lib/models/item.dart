/// Item model

class Item {
  final int id;
  final String itemName;
  final String? description;
  final String? createdAt;

  Item({
    required this.id,
    required this.itemName,
    this.description,
    this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      itemName: json['item_name'],
      description: json['description'],
      createdAt: json['created_at'],
    );
  }

  @override
  String toString() => itemName;
}
