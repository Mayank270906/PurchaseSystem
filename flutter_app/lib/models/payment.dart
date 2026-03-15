/// Payment model

class Payment {
  final int id;
  final int vendorId;
  final String? vendorName;
  final double amount;
  final String? purpose;
  final String? paymentMethod;
  final String datetime;
  final String? recordedBy;
  final String? notes;

  Payment({
    required this.id,
    required this.vendorId,
    this.vendorName,
    required this.amount,
    this.purpose,
    this.paymentMethod,
    required this.datetime,
    this.recordedBy,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      amount: double.parse(json['amount'].toString()),
      purpose: json['purpose'],
      paymentMethod: json['payment_method'],
      datetime: json['datetime'],
      recordedBy: json['recorded_by'],
      notes: json['notes'],
    );
  }
}
