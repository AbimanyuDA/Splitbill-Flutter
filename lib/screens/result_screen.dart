import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_bill_provider.dart';
import 'split_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  String _fmt(double v) {
    if (v == v.truncate())
      return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final receipt = provider.receipt;
    if (receipt == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Hasil Scan Nota'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => provider.addItem(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(
                  title: 'Item (${receipt.items.length})',
                  icon: Icons.receipt_long,
                ),
                const SizedBox(height: 8),
                ...receipt.items.map(
                  (item) => _ItemCard(
                    item: item,
                    onDelete: () => provider.removeItem(item.id),
                    onNameChange: (v) => provider.updateItemName(item.id, v),
                    onPriceChange: (v) => provider.updateItemPrice(item.id, v),
                    onQtyChange: (v) => provider.updateItemQty(item.id, v),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Pajak & Ongkir',
                  icon: Icons.calculate_outlined,
                ),
                const SizedBox(height: 8),
                _ExtraCard(
                  label: 'Pajak',
                  value: receipt.tax,
                  onChanged: provider.updateTax,
                ),
                const SizedBox(height: 8),
                _ExtraCard(
                  label: 'Ongkos Kirim',
                  value: receipt.shipping,
                  onChanged: provider.updateShipping,
                ),
                const SizedBox(height: 16),
                _TotalSummary(receipt: receipt, fmt: _fmt),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SplitScreen())),
            icon: const Icon(Icons.people_alt_rounded),
            label: const Text('Lanjut', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFF4361EE),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4361EE)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onDelete;
  final ValueChanged<String> onNameChange;
  final ValueChanged<double> onPriceChange;
  final ValueChanged<int> onQtyChange;

  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.onNameChange,
    required this.onPriceChange,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.name,
                    decoration: const InputDecoration(
                      labelText: 'Nama Item',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: onNameChange,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.price.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      prefixText: 'Rp ',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onPriceChange(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: item.qty.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => onQtyChange(int.tryParse(v) ?? 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraCard extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _ExtraCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          initialValue: value.toStringAsFixed(0),
          decoration: InputDecoration(
            labelText: label,
            prefixText: 'Rp ',
            border: InputBorder.none,
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
        ),
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  final dynamic receipt;
  final String Function(double) fmt;

  const _TotalSummary({required this.receipt, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF4361EE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('Subtotal', fmt(receipt.subtotal), false),
            if (receipt.tax > 0) _summaryRow('Pajak', fmt(receipt.tax), false),
            if (receipt.shipping > 0)
              _summaryRow('Ongkir', fmt(receipt.shipping), false),
            const Divider(color: Colors.white38, height: 16),
            _summaryRow('Total', fmt(receipt.total), true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool bold) {
    final style = TextStyle(
      color: Colors.white,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 18 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
