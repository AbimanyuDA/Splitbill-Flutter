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
          left: 24,
          right: 24,
          top: 24,
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          final provider = ctx.watch<SplitBillProvider>();
          final assignees = provider.assigneesOf(item.id);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_fmt(item.total),
                    style:
                        const TextStyle(color: Color(0xFF4361EE), fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        provider.assignAll(item.id);
                        setState(() {});
                      },
                      child: const Text('Semua'),
                    ),
                    TextButton(
                      onPressed: () {
                        provider.unassignAll(item.id);
                        setState(() {});
                      },
                      child: const Text('Hapus semua'),
                    ),
                  ],
                ),
                ...provider.people.map((p) => CheckboxListTile(
                      title: Text(p.name),
                      value: assignees.contains(p.id),
                      activeColor: const Color(0xFF4361EE),
                      onChanged: (_) {
                        provider.toggleAssignment(item.id, p.id);
                        setState(() {});
                      },
                    )),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF4361EE),
                  ),
                  child: const Text('Selesai'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showSummary(BuildContext context) {
    final provider = context.read<SplitBillProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ringkasan Tagihan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: provider.people.map((p) {
                    final subtotal = provider.subtotalFor(p.id);
                    final total = provider.totalFor(p.id);
                    final items = provider.receipt!.items
                        .where((i) => provider.assigneesOf(i.id).contains(p.id))
                        .toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(_fmt(total),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF4361EE))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...items.map((i) {
                              final count = provider.assigneesOf(i.id).length;
                              final share = i.total / count;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      count > 1
                                          ? '${i.name} (÷$count)'
                                          : i.name,
                                      style:
                                          TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(_fmt(share),
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              );
                            }),
                            if (provider.receipt!.tax > 0 ||
                                provider.receipt!.shipping > 0) ...[
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Pajak+Ongkir (proporsional)',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12)),
                                  Text(
                                      _fmt(total - subtotal),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
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
        title: const Text('Splitbill'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Daftar orang
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Siapa saja?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
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
                    children: provider.people
                        .map((p) => Chip(
                              label: Text(p.name),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () =>
                                  provider.removePerson(p.id),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text('Tap item untuk assign ke orang',
                      style: TextStyle(color: Colors.grey)),
                ),
                ...receipt.items.map((item) {
                  final assignees = provider.assigneesOf(item.id);
                  final assigneeNames = assignees
                      .map((id) => provider.people
                          .firstWhere((p) => p.id == id,
                              orElse: () => Person(id: '', name: '?'))
                          .name)
                      .where((n) => n.isNotEmpty)
                      .join(', ');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                    child: ListTile(
                      onTap: provider.people.isEmpty
                          ? null
                          : () => _showAssignDialog(context, item),
                      title: Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: assignees.isEmpty
                          ? Text('Belum di-assign',
                              style: TextStyle(color: Colors.red[300]))
                          : Text(assigneeNames,
                              style:
                                  const TextStyle(color: Color(0xFF4361EE))),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_fmt(item.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          if (item.qty > 1)
                            Text('${item.qty}x ${_fmt(item.price)}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500])),
                        ],
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
