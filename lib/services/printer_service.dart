import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:flutter/painting.dart';

import '../models/transaksi.dart';
import '../utils/formatters.dart';

class PrinterService {
  final FlutterClassicBluetooth _bluetooth = FlutterClassicBluetooth();
  BtcConnection? _connection;
  String? _connectedMac;
  String? _connectedName;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String? get connectedMac => _connectedMac;
  String? get connectedName => _connectedName;

  Future<bool> checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return true;
    final status = await _bluetooth.requestPermissions();
    return status == BtcPermissionStatus.granted ||
        status == BtcPermissionStatus.notRequired;
  }

  Future<bool> isBluetoothOn() async {
    try {
      final enabled = await _bluetooth.isEnabled();
      return enabled;
    } catch (_) {
      return false;
    }
  }

  Future<List<BtcDevice>> scanDevices() async {
    try {
      final devices = await _bluetooth.scan(
        timeout: const Duration(seconds: 8),
      );
      return devices;
    } catch (_) {
      return [];
    }
  }

  Future<List<BtcDevice>> getPairedDevices() async {
    try {
      final devices = await _bluetooth.getPairedDevices();
      return devices;
    } catch (_) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      await _connection?.close();
      _connection = await _bluetooth.connect(
        address: macAddress,
        timeout: const Duration(seconds: 15),
      );

      _isConnected = _connection!.isConnected;
      if (_isConnected) {
        _connectedMac = macAddress;
      } else {
        _connection = null;
      }
      return _isConnected;
    } catch (_) {
      _connection = null;
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.finish();
    } catch (_) {}
    _connection = null;
    _isConnected = false;
    _connectedMac = null;
    _connectedName = null;
  }

  Future<bool> printTest() async {
    if (!_isConnected || _connection == null) return false;
    final bytes = _buildTestBytes();
    try {
      await _connection!.output.writeBytes(bytes);
      await _connection!.output.allSent;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> printStruk(Transaksi transaksi, String namaToko,
      {String alamat = '',
      String noTelp = '',
      String sloganPenutup = 'Terima kasih!',
      String footerStruk = 'Barang yang sudah dibeli\ntidak dapat dikembalikan.',
      String logoPath = ''}) async {
    if (!_isConnected || _connection == null) return false;
    final bytes = await _buildStrukBytes(transaksi, namaToko,
        alamat: alamat,
        noTelp: noTelp,
        sloganPenutup: sloganPenutup,
        footerStruk: footerStruk,
        logoPath: logoPath);
    try {
      await _connection!.output.writeBytes(bytes);
      await _connection!.output.allSent;
      return true;
    } catch (_) {
      return false;
    }
  }

  List<int> _buildTestBytes() {
    final List<int> bytes = [];
    bytes.addAll(_initialize());
    bytes.addAll(_centerAlign());
    bytes.addAll(_bold(true));
    bytes.addAll(_textSize(2, 2));
    bytes.addAll(_lineText(namaToko: 'Tokoku'));
    bytes.addAll(_textSize(1, 1));
    bytes.addAll(_bold(false));
    bytes.addAll(_lineText(namaToko: 'Jl. Contoh No. 123'));
    bytes.addAll(_lineText(namaToko: 'Telp: 08123456789'));
    bytes.addAll(_lineHR());
    bytes.addAll(_bold(true));
    bytes.addAll(_lineText(namaToko: 'STRUK TEST'));
    bytes.addAll(_bold(false));
    bytes.addAll(_lineText(namaToko: 'Printer berhasil terhubung!'));
    bytes.addAll(_lineHR());
    bytes.addAll(_centerAlign());
    bytes.addAll(_lineText(namaToko: formatDate(DateTime.now())));
    bytes.addAll(_feedLines(3));
    bytes.addAll(_cut());
    bytes.addAll(_leftAlign());
    return bytes;
  }

  Future<List<int>> _buildStrukBytes(Transaksi transaksi, String namaToko,
      {String alamat = '',
      String noTelp = '',
      String sloganPenutup = 'Terima kasih!',
      String footerStruk = 'Barang yang sudah dibeli\ntidak dapat dikembalikan.',
      String logoPath = ''}) async {
    final List<int> bytes = [];

    bytes.addAll(_initialize());
    bytes.addAll(_centerAlign());
    bytes.addAll(_bold(true));

    // Print logo if available
    if (logoPath.isNotEmpty) {
      try {
        final logoFile = File(logoPath);
        if (await logoFile.exists()) {
          final logoBytes = await _encodeLogoForPrinter(logoFile);
          if (logoBytes != null) {
            bytes.addAll(logoBytes);
            bytes.addAll(Uint8List.fromList(utf8.encode('\n')));
          }
        }
      } catch (_) {}
    }

    bytes.addAll(_textSize(2, 2));
    bytes.addAll(_lineText(namaToko: namaToko));
    bytes.addAll(_textSize(1, 1));
    bytes.addAll(_bold(false));

    if (alamat.isNotEmpty) {
      bytes.addAll(_lineText(namaToko: alamat));
    }
    if (noTelp.isNotEmpty) {
      bytes.addAll(_lineText(namaToko: 'Telp: $noTelp'));
    }
    if (alamat.isNotEmpty || noTelp.isNotEmpty) {
      bytes.addAll(_lineHR());
    }

    bytes.addAll(_lineText(namaToko: formatDate(transaksi.timestamp)));
    bytes.addAll(_lineHR());

    for (final item in transaksi.items) {
      final qty = item.qty;
      final satuan = item.satuan.isNotEmpty ? item.satuan : 'pcs';
      bytes.addAll(_leftAlign());
      bytes.addAll(_lineText(namaToko: item.nama));
      final unitPrice = qty > 0 ? item.subtotal / qty : item.subtotal;
      final detail = '${formatQty(qty)} $satuan x ${formatRupiah(unitPrice)}';
      final price = formatRupiah(item.subtotal);
      bytes.addAll(_lineTwoCol(detail, price));
    }

    bytes.addAll(_lineHR());
    bytes.addAll(_bold(true));
    bytes.addAll(_lineTwoCol('TOTAL', formatRupiah(transaksi.total)));
    bytes.addAll(_bold(false));
    bytes.addAll(_lineTwoCol('BAYAR', formatRupiah(transaksi.bayar)));
    bytes.addAll(_lineTwoCol('KEMBALI', formatRupiah(transaksi.kembalian)));
    bytes.addAll(_lineHR());
    bytes.addAll(_centerAlign());
    bytes.addAll(_bold(true));
    bytes.addAll(_lineText(namaToko: sloganPenutup));
    bytes.addAll(_bold(false));
    if (footerStruk.isNotEmpty) {
      bytes.addAll(_lineText(namaToko: footerStruk));
    }
    bytes.addAll(_feedLines(3));
    bytes.addAll(_cut());
    bytes.addAll(_leftAlign());

    return bytes;
  }

  List<int> _initialize() => [0x1B, 0x40];

  List<int> _textSize(int width, int height) {
    int n = 0;
    if (width == 2) n |= 0x10;
    if (height == 2) n |= 0x01;
    return [0x1D, 0x21, n];
  }

  List<int> _bold(bool on) => [0x1B, 0x45, on ? 0x01 : 0x00];

  List<int> _centerAlign() => [0x1B, 0x61, 0x01];
  List<int> _leftAlign() => [0x1B, 0x61, 0x00];

  List<int> _lineText({required String namaToko}) {
    return Uint8List.fromList(utf8.encode('$namaToko\n'));
  }

  List<int> _lineHR() {
    return Uint8List.fromList(utf8.encode('--------------------------------\n'));
  }

  List<int> _lineTwoCol(String left, String right) {
    final width = 32;
    final rightLen = right.length;
    final leftLen = width - rightLen;
    final padded = left.padRight(leftLen) + right;
    return Uint8List.fromList(utf8.encode('$padded\n'));
  }

  List<int> _feedLines(int lines) {
    return [0x1B, 0x64, lines];
  }

  List<int> _cut() => [0x1D, 0x56, 0x00];

  Future<Uint8List?> _encodeLogoForPrinter(File logoFile) async {
    try {
      final bytes = await logoFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Scale to max 384px width (80mm paper) or 288px (58mm)
      final maxWidth = 300;
      final aspectRatio = image.width / image.height;
      final scaledWidth = min(image.width, maxWidth).toInt();
      final scaledHeight = (scaledWidth / aspectRatio).toInt();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final resizedImage =
          await picture.toImage(scaledWidth, scaledHeight);
      final byteData =
          await resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final rgba = byteData.buffer.asUint8List();
      // Convert RGBA to monochrome bitmap for ESC/POS
      final bitmapBytes = _encodeBitmapESC(rgba, scaledWidth, scaledHeight);
      return Uint8List.fromList(bitmapBytes);
    } catch (_) {
      return null;
    }
  }

  List<int> _encodeBitmapESC(Uint8List rgba, int width, int height) {
    final List<int> bytes = [];
    final int bytesPerRow = (width + 7) ~/ 8;

    // GS v 0 (raster bit image)
    bytes.addAll([0x1D, 0x76, 0x30]);
    bytes.addAll([
      bytesPerRow & 0xFF,
      (bytesPerRow >> 8) & 0xFF,
      height & 0xFF,
      (height >> 8) & 0xFF,
    ]);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < bytesPerRow; x++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final px = x * 8 + bit;
          if (px < width) {
            final offset = (y * width + px) * 4;
            final r = rgba[offset];
            final g = rgba[offset + 1];
            final b = rgba[offset + 2];
            final luminance = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
            if (luminance < 128) {
              byte |= (0x80 >> bit);
            }
          }
        }
        bytes.add(byte);
      }
    }
    return bytes;
  }
}
