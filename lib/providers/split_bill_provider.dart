import 'package:flutter/foundation.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';

class Person {
  final String id;
  String name;
  Person({required this.id, required this.name});
}

class SplitBillProvider extends ChangeNotifier {
  Receipt? receipt;
  final List<Person> people = [];

  // itemId -> { personId -> qty yang diambil orang ini }
  final Map<String, Map<String, int>> _assignments = {};

  void setReceipt(Receipt r) {
    receipt = r;
    _assignments.clear();
    notifyListeners();
  }

  void addPerson(String name) {
    people.add(Person(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name));
    notifyListeners();
  }

  void removePerson(String personId) {
    people.removeWhere((p) => p.id == personId);
    for (final map in _assignments.values) {
      map.remove(personId);
    }
    notifyListeners();
  }

  // Berapa unit item ini yang diambil oleh personId
  int qtyFor(String itemId, String personId) =>
      _assignments[itemId]?[personId] ?? 0;

  // Set qty seseorang untuk item tertentu
  void setQty(String itemId, String personId, int qty) {
    final item = receipt?.items.firstWhere((i) => i.id == itemId);
    if (item == null) return;
    final map = _assignments.putIfAbsent(itemId, () => {});
    if (qty <= 0) {
      map.remove(personId);
    } else {
      map[personId] = qty;
    }
    notifyListeners();
  }

  // Total qty yang sudah di-assign untuk satu item
  int assignedQtyTotal(String itemId) {
    final map = _assignments[itemId];
    if (map == null) return 0;
    return map.values.fold(0, (a, b) => a + b);
  }

  // Sisa qty yang belum di-assign
  int remainingQty(String itemId) {
    final item = receipt?.items.firstWhere((i) => i.id == itemId);
    if (item == null) return 0;
    return item.qty - assignedQtyTotal(itemId);
  }

  // Daftar orang yang punya qty > 0 untuk item ini
  List<String> assigneesOf(String itemId) {
    final map = _assignments[itemId];
    if (map == null) return [];
    return map.entries.where((e) => e.value > 0).map((e) => e.key).toList();
  }

  // Bagi rata semua qty item ke semua orang
  void distributeEvenly(String itemId) {
    final item = receipt?.items.firstWhere((i) => i.id == itemId);
    if (item == null || people.isEmpty) return;
    final map = _assignments.putIfAbsent(itemId, () => {});
    map.clear();
    final base = item.qty ~/ people.length;
    int remainder = item.qty % people.length;
    for (final p in people) {
      final extra = remainder > 0 ? 1 : 0;
      remainder--;
      if (base + extra > 0) map[p.id] = base + extra;
    }
    notifyListeners();
  }

  void unassignAll(String itemId) {
    _assignments[itemId] = {};
    notifyListeners();
  }

  // Subtotal item yang ditanggung tiap orang (berdasarkan qty masing-masing)
  double subtotalFor(String personId) {
    if (receipt == null) return 0;
    double total = 0;
    for (final item in receipt!.items) {
      final qty = qtyFor(item.id, personId);
      total += qty * item.price;
    }
    return total;
  }

  // Total termasuk pajak & ongkir proporsional
  double totalFor(String personId) {
    if (receipt == null) return 0;
    final sub = subtotalFor(personId);
    final totalSub = _totalAssignedSubtotal;
    if (totalSub == 0) return sub;
    final extra = receipt!.tax + receipt!.shipping;
    return sub + (sub / totalSub) * extra;
  }

  double get _totalAssignedSubtotal =>
      people.fold(0.0, (sum, p) => sum + subtotalFor(p.id));

  // Item dianggap selesai kalau total assigned qty == item.qty
  bool get isFullyAssigned {
    if (receipt == null) return false;
    return receipt!.items.every((item) => assignedQtyTotal(item.id) == item.qty);
  }

  void updateItemName(String itemId, String name) {
    receipt?.items.firstWhere((i) => i.id == itemId).name = name;
    notifyListeners();
  }

  void updateItemPrice(String itemId, double price) {
    receipt?.items.firstWhere((i) => i.id == itemId).price = price;
    notifyListeners();
  }

  void updateItemQty(String itemId, int qty) {
    receipt?.items.firstWhere((i) => i.id == itemId).qty = qty;
    // Reset assignment jika qty berubah
    _assignments.remove(itemId);
    notifyListeners();
  }

  void addItem() {
    receipt?.items.add(ReceiptItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Item baru',
      price: 0,
    ));
    notifyListeners();
  }

  void removeItem(String itemId) {
    receipt?.items.removeWhere((i) => i.id == itemId);
    _assignments.remove(itemId);
    notifyListeners();
  }

  void updateTax(double value) {
    if (receipt != null) {
      receipt!.tax = value;
      notifyListeners();
    }
  }

  void updateShipping(double value) {
    if (receipt != null) {
      receipt!.shipping = value;
      notifyListeners();
    }
  }

  void reset() {
    receipt = null;
    people.clear();
    _assignments.clear();
    notifyListeners();
  }
}
