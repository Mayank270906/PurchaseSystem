/// Vendor model

class Vendor {
  final int id;
  final String vendorName;
  final String? phone;
  final String? address;
  final String? notes;
  final String? createdAt;

  Vendor({
    required this.id,
    required this.vendorName,
    this.phone,
    this.address,
    this.notes,
    this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      vendorName: json['vendor_name'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      createdAt: json['created_at'],
    );
  }

  @override
  String toString() => vendorName;
}
