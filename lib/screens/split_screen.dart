import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_bill_provider.dart';

class SplitScreen extends StatelessWidget {
  const SplitScreen({super.key});

  String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  void _showAddPerson(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Orang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nama',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  context.read<SplitBillProvider>().addPerson(v.trim());
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  context.read<SplitBillProvider>().addPerson(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF4361EE),
              ),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AssignDialog(item: item, fmt: _fmt),
    );
  }

  void _showSummary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final provider = ctx.read<SplitBillProvider>();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          builder: (ctx, scroll) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Tagihan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: [
                      ...provider.people.map((p) {
                        final subtotal = provider.subtotalFor(p.id);
                        final total = provider.totalFor(p.id);
                        final itemsWithQty = provider.receipt!.items
                            .where((i) => provider.qtyFor(i.id, p.id) > 0)
                            .toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama + total — fix overflow
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _fmt(total),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF4361EE)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Daftar item orang ini
                                ...itemsWithQty.map((i) {
                                  final qty = provider.qtyFor(i.id, p.id);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            qty > 1 ? '${i.name} ×$qty' : i.name,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fmt(qty * i.price),
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                // Pajak + ongkir proporsional
                                if (provider.receipt!.tax > 0 ||
                                    provider.receipt!.shipping > 0) ...[
                                  const Divider(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Pajak & Ongkir (proporsional)',
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        _fmt(total - subtotal),
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final receipt = provider.receipt;
    if (receipt == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Splitbill Aja'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header: daftar orang
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Siapa saja?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAddPerson(context),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
                if (provider.people.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Belum ada orang. Tap Tambah.',
                        style: TextStyle(color: Colors.grey[400])),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: provider.people
                        .map((p) => Chip(
                              label: Text(p.name),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => provider.removePerson(p.id),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Daftar item
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    provider.people.isEmpty
                        ? 'Tambah orang dulu, lalu tap item untuk assign'
                        : 'Tap item untuk atur siapa ambil berapa',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ...receipt.items.map((item) {
                  final assigned = provider.assignedQtyTotal(item.id);
                  final remaining = provider.remainingQty(item.id);
                  final isDone = assigned == item.qty && item.qty > 0;

                  // Ringkasan assign: "A ×2, B ×1"
                  final assignSummary = provider.people
                      .where((p) => provider.qtyFor(item.id, p.id) > 0)
                      .map((p) {
                        final q = provider.qtyFor(item.id, p.id);
                        return q > 1 ? '${p.name} ×$q' : p.name;
                      })
                      .join(', ');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: provider.people.isEmpty
                          ? null
                          : () => _showAssignDialog(context, item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            // Status icon
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : assigned > 0
                                      ? Icons.pending
                                      : Icons.radio_button_unchecked,
                              color: isDone
                                  ? const Color(0xFF06D6A0)
                                  : assigned > 0
                                      ? Colors.orange
                                      : Colors.grey[300],
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  assigned == 0
                                      ? Text('Belum di-assign',
                                          style: TextStyle(
                                              color: Colors.red[300],
                                              fontSize: 12))
                                      : Text(assignSummary,
                                          style: const TextStyle(
                                              color: Color(0xFF4361EE),
                                              fontSize: 12),
                                          overflow: TextOverflow.ellipsis),
                                  if (!isDone && assigned > 0)
                                    Text('Sisa $remaining unit',
                                        style: TextStyle(
                                            color: Colors.orange[700],
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_fmt(item.total),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                if (item.qty > 1)
                                  Text('${item.qty}× ${_fmt(item.price)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: provider.people.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showSummary(context),
                  icon: const Icon(Icons.summarize_rounded),
                  label: const Text('Lihat Ringkasan',
                      style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: provider.isFullyAssigned
                        ? const Color(0xFF06D6A0)
                        : const Color(0xFF4361EE),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _AssignDialog extends StatefulWidget {
  final dynamic item;
  final String Function(double) fmt;
  const _AssignDialog({required this.item, required this.fmt});

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  // personId -> controller
  final Map<String, TextEditingController> _controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllers();
  }

  void _syncControllers() {
    final provider = context.read<SplitBillProvider>();
    for (final p in provider.people) {
      final qty = provider.qtyFor(widget.item.id, p.id);
      if (!_controllers.containsKey(p.id)) {
        _controllers[p.id] = TextEditingController(text: qty == 0 ? '' : '$qty');
      }
    }
  }

  void _updateFromText(SplitBillProvider provider, String personId, String value) {
    final parsed = int.tryParse(value) ?? 0;
    final current = provider.qtyFor(widget.item.id, personId);
    final remaining = provider.remainingQty(widget.item.id);
    final max = current + remaining;
    final clamped = parsed.clamp(0, max);
    provider.setQty(widget.item.id, personId, clamped);
    // Koreksi field jika nilai di-clamp
    if (clamped != parsed) {
      final ctrl = _controllers[personId]!;
      ctrl.text = clamped == 0 ? '' : '$clamped';
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
    setState(() {});
  }

  void _setQty(SplitBillProvider provider, String personId, int newQty) {
    provider.setQty(widget.item.id, personId, newQty);
    final ctrl = _controllers[personId]!;
    ctrl.text = newQty == 0 ? '' : '$newQty';
    ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitBillProvider>();
    final item = widget.item;
    final assigned = provider.assignedQtyTotal(item.id);
    final remaining = provider.remainingQty(item.id);
    _syncControllers();

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(widget.fmt(item.price),
                  style: const TextStyle(color: Color(0xFF4361EE), fontSize: 13)),
              Text(' × ${item.qty} = ${widget.fmt(item.total)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.qty > 0 ? assigned / item.qty : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      assigned == item.qty
                          ? const Color(0xFF06D6A0)
                          : const Color(0xFF4361EE),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$assigned/${item.qty}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: assigned == item.qty
                      ? const Color(0xFF06D6A0)
                      : remaining > 0 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Sisa $remaining unit belum di-assign',
                  style: TextStyle(color: Colors.orange[700], fontSize: 12)),
            ),
          const SizedBox(height: 4),

          // Tombol bagi rata / reset
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  provider.distributeEvenly(item.id);
                  // Sync semua controller setelah distribute
                  for (final p in provider.people) {
                    final q = provider.qtyFor(item.id, p.id);
                    final ctrl = _controllers[p.id];
                    if (ctrl != null) {
                      ctrl.text = q == 0 ? '' : '$q';
                      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
                    }
                  }
                  setState(() {});
                },
                icon: const Icon(Icons.balance, size: 16),
                label: const Text('Bagi rata'),
              ),
              TextButton.icon(
                onPressed: () {
                  provider.unassignAll(item.id);
                  for (final ctrl in _controllers.values) { ctrl.text = ''; }
                  setState(() {});
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),

          // Stepper + input per orang
          ...provider.people.map((p) {
            final qty = provider.qtyFor(item.id, p.id);
            final ctrl = _controllers[p.id]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                        if (qty > 0)
                          Text(widget.fmt(qty * item.price as double),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _QtyButton(
                    icon: Icons.remove,
                    enabled: qty > 0,
                    onTap: () => _setQty(provider, p.id, qty - 1),
                  ),
                  // Input angka langsung
                  SizedBox(
                    width: 48,
                    height: 36,
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => _updateFromText(provider, p.id, v),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    enabled: remaining > 0,
                    onTap: () => _setQty(provider, p.id, qty + 1),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF4361EE),
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF4361EE).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? const Color(0xFF4361EE) : Colors.grey[300]),
      ),
    );
  }
}
