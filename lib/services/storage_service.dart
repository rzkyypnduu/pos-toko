import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/barang.dart';
import '../models/transaksi.dart';

class StorageService {
  static const _barangFile = 'barang.json';
  static const _transaksiFile = 'transaksi.json';
  static const _settingsFile = 'settings.json';

  Future<String> get _basePath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> _getFile(String filename) async {
    final path = await _basePath;
    return File('$path/$filename');
  }

  Future<List<Barang>> loadBarang() async {
    try {
      final file = await _getFile(_barangFile);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => Barang.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBarang(List<Barang> barangList) async {
    final file = await _getFile(_barangFile);
    final jsonList = barangList.map((e) => e.toMap()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<List<Transaksi>> loadTransaksi() async {
    try {
      final file = await _getFile(_transaksiFile);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => Transaksi.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTransaksi(List<Transaksi> transaksiList) async {
    final file = await _getFile(_transaksiFile);
    final jsonList = transaksiList.map((e) => e.toMap()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final file = await _getFile(_settingsFile);
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      return {};
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final file = await _getFile(_settingsFile);
    await file.writeAsString(jsonEncode(settings));
  }

  static const _logoFile = 'logo_toko.png';

  Future<String> saveLogo(File sourceFile) async {
    final path = await _basePath;
    final dest = File('$path/$_logoFile');
    await sourceFile.copy(dest.path);
    return dest.path;
  }

  Future<File?> loadLogo() async {
    try {
      final path = await _basePath;
      final file = File('$path/$_logoFile');
      if (await file.exists()) return file;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteLogo() async {
    try {
      final path = await _basePath;
      final file = File('$path/$_logoFile');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
