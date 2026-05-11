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

  // itemId -> list of personId yang menanggung item ini
  final Map<String, List<String>> _assignments = {};

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
    _assignments.forEach((itemId, ids) => ids.remove(personId));
    notifyListeners();
  }

  List<String> assigneesOf(String itemId) => _assignments[itemId] ?? [];

  void toggleAssignment(String itemId, String personId) {
    final list = _assignments.putIfAbsent(itemId, () => []);
    if (list.contains(personId)) {
      list.remove(personId);
    } else {
      list.add(personId);
    }
    notifyListeners();
  }

  void assignAll(String itemId) {
    _assignments[itemId] = people.map((p) => p.id).toList();
    notifyListeners();
  }

  void unassignAll(String itemId) {
    _assignments[itemId] = [];
    notifyListeners();
  }

  // Subtotal item yang ditanggung tiap orang
  double subtotalFor(String personId) {
    if (receipt == null) return 0;
    double total = 0;
    for (final item in receipt!.items) {
      final assignees = assigneesOf(item.id);
      if (assignees.contains(personId) && assignees.isNotEmpty) {
        total += item.total / assignees.length;
      }
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

  double get _totalAssignedSubtotal {
    return people.fold(0.0, (sum, p) => sum + subtotalFor(p.id));
  }

  bool get isFullyAssigned {
    if (receipt == null) return false;
    return receipt!.items.every((item) => (assigneesOf(item.id)).isNotEmpty);
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
