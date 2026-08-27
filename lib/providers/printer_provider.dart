import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

import '../services/printer_service.dart';
import '../utils/paper_size.dart';

class PrinterProvider extends ChangeNotifier {
  final PrinterService _service = PrinterService();
  List<BtcDevice> _devices = [];
  bool _isScanning = false;
  bool _isLoadingDevices = false;
  PaperSize _paperSize = PaperSize.mm58;
  bool _autoPrint = false;
  String _namaToko = 'Tokoku';
  String _alamat = '';
  String _noTelp = '';
  String _sloganPenutup = 'Terima kasih!';
  String _footerStruk = 'Barang yang sudah dibeli\ntidak dapat dikembalikan.';
  String _logoPath = '';
  String _selectedAddress = '';
  String _selectedName = '';
  String _connectionStatus = 'notConnected';

  List<BtcDevice> get devices => _devices;
  bool get isConnected => _service.isConnected;
  String? get connectedMac => _service.connectedMac;
  bool get isScanning => _isScanning;
  bool get isLoadingDevices => _isLoadingDevices;
  PaperSize get paperSize => _paperSize;
  bool get autoPrint => _autoPrint;
  String get namaToko => _namaToko;
  String get alamat => _alamat;
  String get noTelp => _noTelp;
  String get sloganPenutup => _sloganPenutup;
  String get footerStruk => _footerStruk;
  String get logoPath => _logoPath;
  String get selectedAddress => _selectedAddress;
  String get selectedName => _selectedName;
  String get connectionStatus => _connectionStatus;

  void _safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set paperSize(PaperSize value) {
    _paperSize = value;
    _safeNotify();
  }

  set autoPrint(bool value) {
    _autoPrint = value;
    _safeNotify();
  }

  set namaToko(String value) {
    _namaToko = value;
    _safeNotify();
  }

  set alamat(String value) {
    _alamat = value;
    _safeNotify();
  }

  set noTelp(String value) {
    _noTelp = value;
    _safeNotify();
  }

  set sloganPenutup(String value) {
    _sloganPenutup = value;
    _safeNotify();
  }

  set footerStruk(String value) {
    _footerStruk = value;
    _safeNotify();
  }

  set logoPath(String value) {
    _logoPath = value;
    _safeNotify();
  }

  Future<void> loadSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('autoPrint')) {
      _autoPrint = settings['autoPrint'] == true;
    }
    if (settings.containsKey('namaToko')) {
      _namaToko = settings['namaToko'] ?? 'Tokoku';
    }
    if (settings.containsKey('alamat')) {
      _alamat = settings['alamat'] ?? '';
    }
    if (settings.containsKey('noTelp')) {
      _noTelp = settings['noTelp'] ?? '';
    }
    if (settings.containsKey('sloganPenutup')) {
      _sloganPenutup = settings['sloganPenutup'] ?? 'Terima kasih!';
    }
    if (settings.containsKey('footerStruk')) {
      _footerStruk = settings['footerStruk'] ?? 'Barang yang sudah dibeli\ntidak dapat dikembalikan.';
    }
    if (settings.containsKey('logoPath')) {
      _logoPath = settings['logoPath'] ?? '';
    }
    if (settings.containsKey('paperSize')) {
      _paperSize =
          settings['paperSize'] == 'mm80' ? PaperSize.mm80 : PaperSize.mm58;
    }
    _selectedAddress = settings['selectedAddress'] ?? '';
    _selectedName = settings['selectedName'] ?? '';
    _safeNotify();
  }

  Map<String, dynamic> toSettingsMap() {
    return {
      'autoPrint': _autoPrint,
      'namaToko': _namaToko,
      'alamat': _alamat,
      'noTelp': _noTelp,
      'sloganPenutup': _sloganPenutup,
      'footerStruk': _footerStruk,
      'logoPath': _logoPath,
      'paperSize': _paperSize == PaperSize.mm80 ? 'mm80' : 'mm58',
      'selectedAddress': _selectedAddress,
      'selectedName': _selectedName,
    };
  }

  Future<bool> checkAndRequestPermissions() async {
    return await _service.checkAndRequestPermissions();
  }

  Future<bool> isConnectedToDevice() async {
    return _service.isConnected;
  }

  Future<void> refreshConnectionStatus() async {
    if (_selectedAddress.isEmpty) {
      _connectionStatus = 'notConnected';
      _safeNotify();
      return;
    }
    _connectionStatus = 'checking';
    _safeNotify();
    final connected = await _service.checkConnection();
    _connectionStatus = connected ? 'connected' : 'notConnected';
    if (!connected) {
      _selectedAddress = '';
      _selectedName = '';
    }
    _safeNotify();
  }

  Future<void> loadSavedDevice() async {
    if (_selectedAddress.isEmpty) return;
    _connectionStatus = 'checking';
    _safeNotify();
    try {
      final connected = await _service.connect(_selectedAddress);
      if (connected) {
        _connectionStatus = 'connected';
      } else {
        _connectionStatus = 'notConnected';
      }
    } catch (_) {
      _connectionStatus = 'notConnected';
    }
    _safeNotify();
  }

  Future<void> loadBondedDevices() async {
    _isLoadingDevices = true;
    _safeNotify();
    try {
      _devices = await _service.getPairedDevices();
    } catch (_) {
      _devices = [];
    }
    _isLoadingDevices = false;
    _safeNotify();
  }

  Future<void> scanDevices() async {
    _isScanning = true;
    _safeNotify();
    try {
      _devices = await _service.scanDevices();
    } catch (_) {
      _devices = [];
    }
    _isScanning = false;
    _safeNotify();
  }

  Future<bool> connect(String macAddress, String name) async {
    final result = await _service.connect(macAddress);
    if (result) {
      _selectedAddress = macAddress;
      _selectedName = name;
      _connectionStatus = 'connected';
    }
    _safeNotify();
    return result;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    _connectionStatus = 'notConnected';
    _safeNotify();
  }

  Future<void> resetSelection() async {
    try {
      await disconnect();
    } catch (_) {}
    _selectedAddress = '';
    _selectedName = '';
    _connectionStatus = 'notConnected';
    _safeNotify();
  }

  Future<bool> ensureConnected() async {
    if (_selectedAddress.isEmpty) return false;
    if (_service.isConnected) {
      _connectionStatus = 'connected';
      _safeNotify();
      return true;
    }
    final result = await _service.connect(_selectedAddress);
    _connectionStatus = result ? 'connected' : 'notConnected';
    _safeNotify();
    return result;
  }

  Future<bool> printTest() async {
    final connected = await ensureConnected();
    if (!connected) return false;
    return await _service.printTest();
  }

  Future<bool> printStruk(dynamic transaksi) async {
    final connected = await ensureConnected();
    if (!connected) return false;
    final paperWidth = _paperSize == PaperSize.mm80 ? 576 : 384;
    return await _service.printStruk(transaksi, _namaToko,
        alamat: _alamat,
        noTelp: _noTelp,
        sloganPenutup: _sloganPenutup,
        footerStruk: _footerStruk,
        logoPath: _logoPath,
        paperWidth: paperWidth);
  }
}
