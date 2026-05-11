import 'receipt_item.dart';

class Receipt {
  List<ReceiptItem> items;
  double tax;
  double shipping;

  Receipt({
    required this.items,
    this.tax = 0,
    this.shipping = 0,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + tax + shipping;

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return Receipt(
      items: items,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
    );
  }
}
