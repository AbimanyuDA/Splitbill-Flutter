class ReceiptItem {
  final String id;
  String name;
  double price;
  int qty;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  double get total => price * qty;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }
}
