import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/barang.dart';
import '../models/transaksi.dart';
import '../providers/barang_provider.dart';
import '../services/storage_service.dart';

class TransaksiProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Transaksi> _transaksiList = [];
  final List<CartItem> _cartItems = [];

  List<Transaksi> get transaksiList => _transaksiList;
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  List<Transaksi> get todayTransaksi {
    return _getTransaksiForDate(DateTime.now());
  }

  double get todayTotal => todayTransaksi.fold(0, (sum, t) => sum + t.total);
  double get todayProfit =>
      todayTransaksi.fold(0, (sum, t) => sum + t.keuntungan);
  int get todayCount => todayTransaksi.length;
  double get todayItemQty =>
      todayTransaksi.fold(0.0, (double sum, t) => sum + t.totalItemQty);

  List<Transaksi> _getTransaksiForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _transaksiList
        .where((t) =>
            t.timestamp.isAfter(start.subtract(const Duration(microseconds: 1))) &&
            t.timestamp.isBefore(end))
        .toList();
  }

  List<Transaksi> getTransaksiForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _transaksiList
        .where((t) =>
            t.timestamp.isAfter(start.subtract(const Duration(microseconds: 1))) &&
            t.timestamp.isBefore(end))
        .toList();
  }

  double getMonthTotal(int year, int month) {
    return getTransaksiForMonth(year, month)
        .fold(0, (sum, t) => sum + t.total);
  }

  double getMonthProfit(int year, int month) {
    return getTransaksiForMonth(year, month)
        .fold(0, (sum, t) => sum + t.keuntungan);
  }

  int getMonthCount(int year, int month) {
    return getTransaksiForMonth(year, month).length;
  }

  double getMonthItemQty(int year, int month) {
    return getTransaksiForMonth(year, month)
        .fold(0.0, (double sum, t) => sum + t.totalItemQty);
  }

  List<Transaksi> getTransaksiByDateRange(DateTime start, DateTime end) {
    return _transaksiList
        .where((t) =>
            t.timestamp.isAfter(start.subtract(const Duration(microseconds: 1))) &&
            t.timestamp.isBefore(end))
        .toList();
  }

  List<Transaksi> get recentTransaksi {
    final sorted = List<Transaksi>.from(_transaksiList)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }

  double get totalSemua => _transaksiList.fold(0, (sum, t) => sum + t.total);
  double get profitSemua =>
      _transaksiList.fold(0, (sum, t) => sum + t.keuntungan);

  List<DailyProfitData> getDailyDataForMonth(int year, int month) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final maxDay = isCurrentMonth ? now.day : daysInMonth;

    final monthTransactions = getTransaksiForMonth(year, month);
    final result = <DailyProfitData>[];

    for (int day = 1; day <= maxDay; day++) {
      final dayTx = monthTransactions
          .where((t) =>
              t.timestamp.year == year &&
              t.timestamp.month == month &&
              t.timestamp.day == day)
          .toList();
      final gross = dayTx.fold(0.0, (double sum, t) => sum + t.total);
      final net = dayTx.fold(0.0, (double sum, t) => sum + t.keuntungan);
      result.add(DailyProfitData(day: day, gross: gross, net: net));
    }
    return result;
  }

  List<MonthlyProfitData> getMonthlyDataLast12Months() {
    final now = DateTime.now();
    final result = <MonthlyProfitData>[];
    for (int i = 11; i >= 0; i--) {
      int m = now.month - i;
      int y = now.year;
      while (m <= 0) {
        m += 12;
        y--;
      }
      final total = getMonthTotal(y, m);
      final profit = getMonthProfit(y, m);
      result.add(MonthlyProfitData(month: m, year: y, gross: total, net: profit));
    }
    return result;
  }

  List<SalesItem> getBestSellingItems(List<Transaksi> transactions) {
    final map = <String, SalesItem>{};
    for (final t in transactions) {
      for (final item in t.items) {
        if (map.containsKey(item.barangId)) {
          final existing = map[item.barangId]!;
          map[item.barangId] = SalesItem(
            barangId: item.barangId,
            nama: item.nama,
            totalQty: existing.totalQty + item.qty,
            totalKotor: existing.totalKotor + item.subtotal,
            totalBersih: existing.totalBersih + item.laba,
          );
        } else {
          map[item.barangId] = SalesItem(
            barangId: item.barangId,
            nama: item.nama,
            totalQty: item.qty,
            totalKotor: item.subtotal,
            totalBersih: item.laba,
          );
        }
      }
    }
    final list = map.values.toList()..sort((a, b) => b.totalQty.compareTo(a.totalQty));
    return list.take(5).toList();
  }

  double cartTotal(BarangProvider barangProvider) {
    double total = 0;
    for (final item in _cartItems) {
      final b = barangProvider.cariById(item.barangId);
      if (b != null) {
        total += b.hargaJual * item.qty;
      }
    }
    return total;
  }

  void tambahKeKeranjang(String barangId, String nama, {String satuan = 'pcs'}) {
    final existing =
        _cartItems.indexWhere((c) => c.barangId == barangId);
    if (existing >= 0) {
      _cartItems[existing].qty += 1;
    } else {
      _cartItems.add(CartItem(barangId: barangId, nama: nama, satuan: satuan));
    }
    notifyListeners();
  }

  void tambahQty(int index) {
    if (index < _cartItems.length) {
      _cartItems[index].qty += 1;
      notifyListeners();
    }
  }

  void kurangiQty(int index) {
    if (index < _cartItems.length && _cartItems[index].qty > 1) {
      _cartItems[index].qty -= 1;
      notifyListeners();
    }
  }

  void setQty(int index, double qty) {
    if (index < _cartItems.length && qty > 0) {
      _cartItems[index].qty = qty;
      notifyListeners();
    }
  }

  void hapusDariKeranjang(int index) {
    if (index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> loadData() async {
    _transaksiList = await _storage.loadTransaksi();
    notifyListeners();
  }

  Future<Transaksi> prosesTransaksi({
    required List<CartItem> cartItems,
    required double bayar,
    required Map<String, Barang> barangMap,
  }) async {
    final items = <TransaksiItem>[];
    double total = 0;

    for (final cart in cartItems) {
      final barang = barangMap[cart.barangId];
      final harga = barang?.hargaJual ?? 0;
      final hargaBeli = barang?.hargaBeli ?? 0;
      items.add(TransaksiItem(
        barangId: cart.barangId,
        nama: cart.nama,
        harga: harga,
        hargaBeli: hargaBeli,
        satuan: cart.satuan,
        qty: cart.qty,
      ));
      total += harga * cart.qty;
    }

    final kembalian = bayar - total;
    final transaksi = Transaksi(
      id: const Uuid().v4().substring(0, 8).toUpperCase(),
      items: items,
      total: total,
      bayar: bayar,
      kembalian: kembalian,
    );

    _transaksiList.add(transaksi);
    await _storage.saveTransaksi(_transaksiList);
    notifyListeners();

    return transaksi;
  }
}

class CartItem {
  final String barangId;
  final String nama;
  final String satuan;
  double qty;

  CartItem({
    required this.barangId,
    required this.nama,
    this.satuan = 'pcs',
    this.qty = 1,
  });
}

class SalesItem {
  final String barangId;
  final String nama;
  final double totalQty;
  final double totalKotor;
  final double totalBersih;

  SalesItem({
    required this.barangId,
    required this.nama,
    required this.totalQty,
    required this.totalKotor,
    required this.totalBersih,
  });
}

class DailyProfitData {
  final int day;
  final double gross;
  final double net;

  DailyProfitData({required this.day, required this.gross, required this.net});
}

class MonthlyProfitData {
  final int month;
  final int year;
  final double gross;
  final double net;

  MonthlyProfitData(
      {required this.month, required this.year, required this.gross, required this.net});
}
