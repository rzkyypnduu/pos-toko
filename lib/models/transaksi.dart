import 'dart:convert';

class TransaksiItem {
  final String barangId;
  final String nama;
  final double harga;
  final double hargaBeli;
  double qty;

  TransaksiItem({
    required this.barangId,
    required this.nama,
    required this.harga,
    this.hargaBeli = 0,
    this.qty = 1,
  });

  double get subtotal => harga * qty;
  double get laba => (harga - hargaBeli) * qty;

  Map<String, dynamic> toMap() {
    return {
      'barangId': barangId,
      'nama': nama,
      'harga': harga,
      'hargaBeli': hargaBeli,
      'qty': qty,
    };
  }

  factory TransaksiItem.fromMap(Map<String, dynamic> map) {
    return TransaksiItem(
      barangId: map['barangId'] ?? '',
      nama: map['nama'] ?? '',
      harga: (map['harga'] ?? 0).toDouble(),
      hargaBeli: (map['hargaBeli'] ?? 0).toDouble(),
      qty: (map['qty'] ?? 1).toDouble(),
    );
  }
}

class Transaksi {
  final String id;
  final List<TransaksiItem> items;
  final double total;
  final double bayar;
  final double kembalian;
  final DateTime timestamp;

  Transaksi({
    required this.id,
    required this.items,
    required this.total,
    required this.bayar,
    required this.kembalian,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get keuntungan {
    double totalKeuntungan = 0;
    for (final item in items) {
      totalKeuntungan += item.laba;
    }
    return totalKeuntungan;
  }

  double get totalItemQty {
    double total = 0;
    for (final item in items) {
      total += item.qty;
    }
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'bayar': bayar,
      'kembalian': kembalian,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] ?? '',
      items: (map['items'] as List?)
              ?.map((e) => TransaksiItem.fromMap(e))
              .toList() ??
          [],
      total: (map['total'] ?? 0).toDouble(),
      bayar: (map['bayar'] ?? 0).toDouble(),
      kembalian: (map['kembalian'] ?? 0).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Transaksi.fromJson(String source) =>
      Transaksi.fromMap(jsonDecode(source));
}
