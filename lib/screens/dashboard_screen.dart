import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/barang_provider.dart';
import '../models/barang.dart';
import '../providers/printer_provider.dart';
import '../providers/transaksi_provider.dart';
import '../utils/formatters.dart';
import '../widgets/profit_charts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

enum _DashboardView { semua, hariIni, bulan, barang }

class _DashboardBodyState extends State<_DashboardBody> {
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  _DashboardView _selectedView = _DashboardView.semua;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth--;
      if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedYear < now.year ||
        (_selectedYear == now.year && _selectedMonth < now.month)) {
      setState(() {
        _selectedMonth++;
        if (_selectedMonth > 12) {
          _selectedMonth = 1;
          _selectedYear++;
        }
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<BarangProvider>().loadData();
        await context.read<TransaksiProvider>().loadData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildViewFilter(),
            const SizedBox(height: 16),
            if (_selectedView == _DashboardView.semua ||
                _selectedView == _DashboardView.hariIni) ...[
              _buildDateFilter(context),
              const SizedBox(height: 16),
              _buildDayCards(context),
            ],
            if (_selectedView == _DashboardView.semua ||
                _selectedView == _DashboardView.bulan) ...[
              _buildMonthHeader(context),
              const SizedBox(height: 12),
              _buildMonthCards(context),
              const SizedBox(height: 24),
              _buildMonthlyProfitChart(context),
              const SizedBox(height: 24),
              _buildDailyProfitChart(context),
            ],
            if (_selectedView == _DashboardView.semua ||
                _selectedView == _DashboardView.barang) ...[
              if (_selectedView == _DashboardView.barang) ...[
                const SizedBox(height: 16),
              ],
              _buildBestSelling(context),
              const SizedBox(height: 16),
              _buildLowStock(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewFilter() {
    final items = [
      (_DashboardView.semua, Icons.dashboard_rounded, 'Semua'),
      (_DashboardView.hariIni, Icons.today, 'Hari Ini'),
      (_DashboardView.bulan, Icons.calendar_month, 'Bulan'),
      (_DashboardView.barang, Icons.inventory_2_outlined, 'Barang'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (view, icon, label) = items[i];
          final selected = _selectedView == view;
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
            onSelected: (_) => setState(() => _selectedView = view),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()},',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.read<PrinterProvider>().namaToko,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            formatDate(DateTime.now()),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today,
                color: Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isToday
                      ? 'Hari Ini'
                      : DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                          .format(_selectedDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (!_isToday)
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedDate = DateTime.now();
                      _selectedMonth = DateTime.now().month;
                      _selectedYear = DateTime.now().year;
                    }),
                    child: const Text(
                      'Kembali ke hari ini',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.edit_calendar, size: 16),
            label: const Text('Pilih'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCards(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final filtered = provider
        .getTransaksiForMonth(_selectedDate.year, _selectedDate.month)
        .where((t) =>
            t.timestamp.year == _selectedDate.year &&
            t.timestamp.month == _selectedDate.month &&
            t.timestamp.day == _selectedDate.day)
        .toList();

    final dayTotal = filtered.fold(0.0, (double sum, t) => sum + t.total);
    final dayCount = filtered.length;
    final dayItemQty = filtered.fold(0.0, (double sum, t) => sum + t.totalItemQty);
    final dayLaba = filtered.fold(0.0, (double sum, t) => sum + t.keuntungan);

    final isTablet = MediaQuery.of(context).size.width >= 600;

    final cards = [
      _StatCard(
        icon: Icons.payments,
        title: 'Penjualan',
        value: formatRupiah(dayTotal),
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
      ),
      _StatCard(
        icon: Icons.receipt_long,
        title: 'Transaksi',
        value: '$dayCount',
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFF2E7D32).withValues(alpha: 0.08),
      ),
      _StatCard(
        icon: Icons.shopping_bag,
        title: 'Item Terjual',
        value: formatQty(dayItemQty),
        color: const Color(0xFFE65100),
        bgColor: const Color(0xFFE65100).withValues(alpha: 0.08),
      ),
      _StatCard(
        icon: Icons.trending_up,
        title: 'Laba Bersih',
        value: formatRupiah(dayLaba),
        color: const Color(0xFF00897B),
        bgColor: const Color(0xFF00897B).withValues(alpha: 0.08),
      ),
    ];

    if (isTablet) {
      return Row(
        children: cards
            .map((c) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c)))
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final monthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;

    return Row(
      children: [
        const Text(
          'Ringkasan Bulanan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left, size: 20),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          color: Colors.grey[600],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${monthNames[_selectedMonth]} $_selectedYear',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : _nextMonth,
          icon: const Icon(Icons.chevron_right, size: 20),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          color: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildMonthCards(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final monthTotal = provider.getMonthTotal(_selectedYear, _selectedMonth);
    final monthCount = provider.getMonthCount(_selectedYear, _selectedMonth);
    final monthItemQty =
        provider.getMonthItemQty(_selectedYear, _selectedMonth);
    final monthLaba = provider.getMonthProfit(_selectedYear, _selectedMonth);

    final isTablet = MediaQuery.of(context).size.width >= 600;

    final cards = [
      _StatCard(
        icon: Icons.payments,
        title: 'Omzet',
        value: formatRupiah(monthTotal),
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
      ),
      _StatCard(
        icon: Icons.receipt_long,
        title: 'Transaksi',
        value: '$monthCount',
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFF2E7D32).withValues(alpha: 0.08),
      ),
      _StatCard(
        icon: Icons.shopping_bag,
        title: 'Total Item',
        value: formatQty(monthItemQty),
        color: const Color(0xFFE65100),
        bgColor: const Color(0xFFE65100).withValues(alpha: 0.08),
      ),
      _StatCard(
        icon: Icons.trending_up,
        title: 'Laba Bersih',
        value: formatRupiah(monthLaba),
        color: const Color(0xFF00897B),
        bgColor: const Color(0xFF00897B).withValues(alpha: 0.08),
      ),
    ];

    if (isTablet) {
      return Row(
        children: cards
            .map((c) => Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c)))
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyProfitChart(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final data = provider.getMonthlyDataLast12Months();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart,
                    color: Color(0xFF1565C0), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Keuntungan Per Bulan',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '12 bulan terakhir',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          MonthlyProfitChart(data: data),
        ],
      ),
    );
  }

  Widget _buildDailyProfitChart(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final data = provider.getDailyDataForMonth(_selectedYear, _selectedMonth);

    final monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart,
                    color: Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keuntungan Harian',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${monthNames[_selectedMonth]} $_selectedYear',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DailyProfitChart(data: data),
        ],
      ),
    );
  }

  Widget _buildBestSelling(BuildContext context) {
    final provider = context.watch<TransaksiProvider>();
    final monthTransactions =
        provider.getTransaksiForMonth(_selectedYear, _selectedMonth);

    final bestSelling = provider.getBestSellingItems(monthTransactions);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star,
                    color: Color(0xFFFF6F00), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Barang Paling Laris',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bestSelling.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Belum ada penjualan bulan ini',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            )
          else
            isTablet
                ? _buildBestSellingTable(bestSelling)
                : _buildBestSellingList(bestSelling),
        ],
      ),
    );
  }

  Widget _buildBestSellingTable(List<SalesItem> items) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Barang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
              Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
              Expanded(flex: 2, child: Text('Kotor', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
              Expanded(flex: 2, child: Text('Bersih', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i.isEven ? Colors.grey.shade50 : Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: i == 0 ? const Color(0xFFFF6F00).withValues(alpha: 0.12) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: i == 0 ? const Color(0xFFFF6F00) : Colors.grey[600])),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.nama,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(formatQty(item.totalQty),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(formatRupiah(item.totalKotor),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
                ),
                Expanded(
                  flex: 2,
                  child: Text(formatRupiah(item.totalBersih),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBestSellingList(List<SalesItem> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: i == 0 ? const Color(0xFFFF6F00).withValues(alpha: 0.12) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: i == 0 ? const Color(0xFFFF6F00) : Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.nama,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                    Text('${formatQty(item.totalQty)} terjual',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _MiniTag(label: 'Kotor: ${formatRupiah(item.totalKotor)}', color: const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  _MiniTag(label: 'Bersih: ${formatRupiah(item.totalBersih)}', color: const Color(0xFF2E7D32)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLowStock(BuildContext context) {
    final barang = context.watch<BarangProvider>();
    final lowStock = barang.lowStockItems;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD32F2F), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Stok Menipis',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              if (lowStock.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${lowStock.length} item',
                    style: const TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStock.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Semua stok aman',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            )
          else
            ...lowStock.map((b) => _LowStockItem(barang: b)),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _LowStockItem extends StatelessWidget {
  final Barang barang;
  const _LowStockItem({required this.barang});

  @override
  Widget build(BuildContext context) {
    final isOut = barang.stok == 0;
    final color = isOut ? const Color(0xFFD32F2F) : const Color(0xFFFF6F00);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                formatQty(barang.stok),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(barang.nama,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(barang.kategori,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOut ? 'Habis' : 'Sisa ${formatQty(barang.stok)}',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
