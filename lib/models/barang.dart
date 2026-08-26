import 'dart:convert';

class Barang {
  final String id;
  final String kode;
  String nama;
  double hargaBeli;
  double hargaJual;
  double stok;
  String kategori;
  String satuan;
  final DateTime createdAt;

  Barang({
    required this.id,
    required this.kode,
    required this.nama,
    this.hargaBeli = 0,
    this.hargaJual = 0,
    this.stok = 0,
    this.kategori = 'Umum',
    this.satuan = 'pcs',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get keuntungan => hargaJual - hargaBeli;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'nama': nama,
      'hargaBeli': hargaBeli,
      'hargaJual': hargaJual,
      'stok': stok,
      'kategori': kategori,
      'satuan': satuan,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'] ?? '',
      kode: map['kode'] ?? '',
      nama: map['nama'] ?? '',
      hargaBeli: (map['hargaBeli'] ?? 0).toDouble(),
      hargaJual: (map['hargaJual'] ?? 0).toDouble(),
      stok: (map['stok'] ?? 0).toDouble(),
      kategori: map['kategori'] ?? 'Umum',
      satuan: map['satuan'] ?? 'pcs',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Barang.fromJson(String source) =>
      Barang.fromMap(jsonDecode(source));

  Barang copyWith({
    String? nama,
    double? hargaBeli,
    double? hargaJual,
    double? stok,
    String? kategori,
    String? satuan,
  }) {
    return Barang(
      id: id,
      kode: kode,
      nama: nama ?? this.nama,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      stok: stok ?? this.stok,
      kategori: kategori ?? this.kategori,
      satuan: satuan ?? this.satuan,
      createdAt: createdAt,
    );
  }
}
