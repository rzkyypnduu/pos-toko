import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/barang.dart';
import '../services/storage_service.dart';

class BarangProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Barang> _barangList = [];
  String _searchQuery = '';
  String _filterKategori = 'Semua';

  List<Barang> get barangList => _barangList;

  List<Barang> get filteredBarang {
    var list = _barangList;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((b) =>
              b.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.kode.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filterKategori != 'Semua') {
      list = list.where((b) => b.kategori == _filterKategori).toList();
    }
    return list;
  }

  String get searchQuery => _searchQuery;
  String get filterKategori => _filterKategori;

  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  set filterKategori(String value) {
    _filterKategori = value;
    notifyListeners();
  }

  int get totalBarang => _barangList.length;

  double get totalStok {
    return _barangList.fold(0, (sum, b) => sum + b.stok);
  }

  List<String> get kategoris {
    final kats = _barangList.map((b) => b.kategori).toSet().toList();
    kats.insert(0, 'Semua');
    return kats;
  }

  Future<void> loadData() async {
    _barangList = await _storage.loadBarang();
    notifyListeners();
  }

  Future<void> tambahBarang(Barang barang) async {
    _barangList.add(barang);
    await _storage.saveBarang(_barangList);
    notifyListeners();
  }

  Future<void> updateBarang(String id, Barang updated) async {
    final index = _barangList.indexWhere((b) => b.id == id);
    if (index != -1) {
      _barangList[index] = updated;
      await _storage.saveBarang(_barangList);
      notifyListeners();
    }
  }

  Future<void> hapusBarang(String id) async {
    _barangList.removeWhere((b) => b.id == id);
    await _storage.saveBarang(_barangList);
    notifyListeners();
  }

  Barang? cariByKode(String kode) {
    try {
      return _barangList.firstWhere((b) => b.kode == kode);
    } catch (_) {
      return null;
    }
  }

  Barang? cariById(String id) {
    try {
      return _barangList.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Barang> cariBarang(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _barangList
        .where((b) =>
            b.kode.toLowerCase().contains(q) ||
            b.nama.toLowerCase().contains(q))
        .toList();
  }

  Future<void> tambahStok(String id, double jumlah) async {
    final index = _barangList.indexWhere((b) => b.id == id);
    if (index != -1) {
      _barangList[index].stok += jumlah;
      await _storage.saveBarang(_barangList);
      notifyListeners();
    }
  }

  Future<void> kurangiStok(String id, double jumlah) async {
    final index = _barangList.indexWhere((b) => b.id == id);
    if (index != -1) {
      _barangList[index].stok =
          (_barangList[index].stok - jumlah).clamp(0, 999999);
      await _storage.saveBarang(_barangList);
      notifyListeners();
    }
  }

  List<Barang> get lowStockItems {
    return _barangList.where((b) => b.stok <= 5).toList()
      ..sort((a, b) => a.stok.compareTo(b.stok));
  }

  String generateId() {
    return const Uuid().v4().substring(0, 8);
  }
}
