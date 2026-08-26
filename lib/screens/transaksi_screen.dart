import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaksi.dart';
import '../providers/transaksi_provider.dart';
import '../utils/formatters.dart';
import '../widgets/responsive_layout.dart';

enum _DateFilter { all, today, thisWeek, thisMonth, custom }

class TransaksiScreen extends StatelessWidget {
  const TransaksiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _TransaksiMobile(),
      tablet: const _TransaksiTablet(),
    );
  }
}

class _TransaksiMobile extends StatelessWidget {
  const _TransaksiMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        centerTitle: false,
      ),
      body: const _TransaksiBody(),
    );
  }
}

class _TransaksiTablet extends StatelessWidget {
  const _TransaksiTablet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        centerTitle: false,
      ),
      body: const _TransaksiBody(),
    );
  }
}

class _TransaksiBody extends StatefulWidget {
  const _TransaksiBody();

  @override
  State<_TransaksiBody> createState() => _TransaksiBodyState();
}

class _TransaksiBodyState extends State<_TransaksiBody> {
  _DateFilter _filter = _DateFilter.all;
  DateTimeRange? _customRange;

  List<Transaksi> _getFiltered(TransaksiProvider provider) {
    final all = List<Transaksi>.from(provider.transaksiList)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    switch (_filter) {
      case _DateFilter.all:
        return all;
      case _DateFilter.today:
        final list = provider.todayTransaksi;
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      case _DateFilter.thisWeek:
        final now = DateTime.now();
        final start = now.subtract(Duration(days: now.weekday - 1));
        final dayStart = DateTime(start.year, start.month, start.day);
        return all.where((t) => t.timestamp.isAfter(dayStart)).toList();
      case _DateFilter.thisMonth:
        final now = DateTime.now();
        final list = provider.getTransaksiForMonth(now.year, now.month);
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      case _DateFilter.custom:
        if (_customRange == null) return all;
        final list = provider.getTransaksiByDateRange(
          _customRange!.start,
          _customRange!.end.add(const Duration(days: 1)),
        );
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
    }
  }

  void _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _filter = _DateFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final filtered = _getFiltered(provider);

    final totalFiltered =
        filtered.fold<double>(0, (sum, t) => sum + t.total);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _DateFilterChip(
                      label: 'Semua',
                      selected: _filter == _DateFilter.all,
                      onTap: () =>
                          setState(() => _filter = _DateFilter.all),
                    ),
                    const SizedBox(width: 6),
                    _DateFilterChip(
                      label: 'Hari Ini',
                      selected: _filter == _DateFilter.today,
                      onTap: () =>
                          setState(() => _filter = _DateFilter.today),
                    ),
                    const SizedBox(width: 6),
                    _DateFilterChip(
                      label: 'Minggu Ini',
                      selected: _filter == _DateFilter.thisWeek,
                      onTap: () =>
                          setState(() => _filter = _DateFilter.thisWeek),
                    ),
                    const SizedBox(width: 6),
                    _DateFilterChip(
                      label: 'Bulan Ini',
                      selected: _filter == _DateFilter.thisMonth,
                      onTap: () =>
                          setState(() => _filter = _DateFilter.thisMonth),
                    ),
                    const SizedBox(width: 6),
                    _DateFilterChip(
                      label: _customRange != null
                          ? '${formatDateShort(_customRange!.start)} - ${formatDateShort(_customRange!.end)}'
                          : 'Pilih Tanggal',
                      selected: _filter == _DateFilter.custom,
                      onTap: _pickCustomRange,
                      icon: Icons.date_range,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt,
                        size: 16, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(
                      '${filtered.length} transaksi',
                      style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      formatRupiah(totalFiltered),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1565C0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Tidak ada transaksi',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('untuk filter yang dipilih',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          child: const Icon(Icons.receipt,
                              color: Color(0xFF2E7D32), size: 18),
                        ),
                        title: Text('#${t.id}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14)),
                        subtitle: Text(
                            '${t.totalItemQty} item | ${formatDate(t.timestamp)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                        trailing: Text(formatRupiah(t.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1565C0))),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                _TransaksiDetailDialog(transaksi: t),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _DateFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _TransaksiDetailDialog extends StatelessWidget {
  final Transaksi transaksi;
  const _TransaksiDetailDialog({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt,
                color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(width: 10),
          Text('Transaksi #${transaksi.id}'),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatDate(transaksi.timestamp),
                style: TextStyle(color: Colors.grey[600])),
            const Divider(),
            ...transaksi.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child:
                              Text('${item.nama} x${formatQty(item.qty)}')),
                      Text(formatRupiah(item.subtotal)),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(formatRupiah(transaksi.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0))),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bayar'),
                Text(formatRupiah(transaksi.bayar)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembali'),
                Text(formatRupiah(transaksi.kembalian)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
