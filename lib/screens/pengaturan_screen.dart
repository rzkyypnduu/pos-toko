import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/transaksi.dart';
import '../providers/printer_provider.dart';
import '../services/storage_service.dart';
import '../utils/paper_size.dart';
import '../widgets/responsive_layout.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _PengaturanMobile(),
      tablet: const _PengaturanTablet(),
    );
  }
}

class _PengaturanMobile extends StatelessWidget {
  const _PengaturanMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: false,
      ),
      body: const _PengaturanBody(),
    );
  }
}

class _PengaturanTablet extends StatelessWidget {
  const _PengaturanTablet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: const _PengaturanBody(),
        ),
      ),
    );
  }
}

class _PengaturanBody extends StatefulWidget {
  const _PengaturanBody();

  @override
  State<_PengaturanBody> createState() => _PengaturanBodyState();
}

class _PengaturanBodyState extends State<_PengaturanBody> {
  final _namaTokoCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _noTelpCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _logoFile;

  @override
  void initState() {
    super.initState();
    final printer = context.read<PrinterProvider>();
    _namaTokoCtrl.text = printer.namaToko;
    _alamatCtrl.text = printer.alamat;
    _noTelpCtrl.text = printer.noTelp;
    _sloganCtrl.text = printer.sloganPenutup;
    _footerCtrl.text = printer.footerStruk;
    _loadLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      printer.refreshConnectionStatus();
    });
  }

  Future<void> _loadLogo() async {
    final storage = StorageService();
    final file = await storage.loadLogo();
    if (mounted && file != null) {
      setState(() => _logoFile = file);
    }
  }

  @override
  void dispose() {
    _namaTokoCtrl.dispose();
    _alamatCtrl.dispose();
    _noTelpCtrl.dispose();
    _sloganCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final printer = context.read<PrinterProvider>();
    printer.namaToko = _namaTokoCtrl.text.trim();
    printer.alamat = _alamatCtrl.text.trim();
    printer.noTelp = _noTelpCtrl.text.trim();
    printer.sloganPenutup = _sloganCtrl.text.trim();
    printer.footerStruk = _footerCtrl.text.trim();

    final storage = StorageService();
    await storage.saveSettings(printer.toSettingsMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan tersimpan')),
      );
    }
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 85,
    );
    if (picked == null) return;

    final storage = StorageService();
    final savedPath = await storage.saveLogo(File(picked.path));
    if (!mounted) return;
    final printer = context.read<PrinterProvider>();
    printer.logoPath = savedPath;
    _saveSettings();

    setState(() => _logoFile = File(savedPath));
  }

  Future<void> _removeLogo() async {
    final storage = StorageService();
    await storage.deleteLogo();
    if (!mounted) return;
    final printer = context.read<PrinterProvider>();
    printer.logoPath = '';
    _saveSettings();
    setState(() => _logoFile = null);
  }

  Future<void> _showDevicePicker() async {
    try {
      final printer = context.read<PrinterProvider>();
      final hasPermission = await printer.checkAndRequestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Izin Bluetooth diperlukan. Aktifkan di pengaturan aplikasi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final outcome = await showModalBottomSheet<_PickerOutcome>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: printer,
          child: _BluetoothDevicePickerSheet(
            savedAddress: printer.selectedAddress,
            savedName: printer.selectedName,
          ),
        ),
      );
      if (outcome == null || !mounted) return;

      if (outcome.released) {
        await printer.resetSelection();
        _saveSettings();
        return;
      }

      if (outcome.device != null) {
        final device = outcome.device!;
        await printer.connect(device.address, device.name ?? 'Printer');
        _saveSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Custom Struk'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage:
                            _logoFile != null ? FileImage(_logoFile!) : null,
                        child: _logoFile == null
                            ? Icon(Icons.store,
                                size: 36, color: Colors.grey.shade400)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1565C0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_logoFile != null)
                Center(
                  child: TextButton(
                    onPressed: _removeLogo,
                    child: const Text('Hapus Logo',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _namaTokoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                onChanged: (_) => _saveSettings(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alamatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (_) => _saveSettings(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noTelpCtrl,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (_) => _saveSettings(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sloganCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slogan Penutup Struk',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_quote),
                ),
                maxLines: 2,
                onChanged: (_) => _saveSettings(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _footerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Footer Struk',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Barang yang sudah dibeli...',
                ),
                maxLines: 2,
                onChanged: (_) => _saveSettings(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReceiptPreview(context),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Preview Struk'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Printer ESC/POS Bluetooth'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto Print Struk'),
                subtitle: const Text('Otomatis cetak setelah transaksi'),
                value: printer.autoPrint,
                onChanged: (val) {
                  printer.autoPrint = val;
                  _saveSettings();
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                title: const Text('Ukuran Kertas'),
                trailing: DropdownButton<PaperSize>(
                  value: printer.paperSize,
                  onChanged: (val) {
                    if (val != null) {
                      printer.paperSize = val;
                      _saveSettings();
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: PaperSize.mm58,
                      child: Text('58mm'),
                    ),
                    DropdownMenuItem(
                      value: PaperSize.mm80,
                      child: Text('80mm'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                onTap: _showDevicePicker,
                title: const Text('Nama Printer'),
                subtitle: _printerSubtitle(printer),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (printer.connectionStatus == 'checking')
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      printer.connectionStatus == 'connected'
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: printer.connectionStatus == 'connected'
                          ? const Color(0xFF2E7D32)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (printer.connectionStatus == 'connected')
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Test Print'),
              subtitle:
                  const Text('Cetak struk test untuk memastikan printer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await printer.printTest();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result
                          ? 'Test print berhasil'
                          : 'Test print gagal'),
                      backgroundColor:
                          result ? const Color(0xFF2E7D32) : Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        if (printer.connectionStatus == 'notConnected' &&
            printer.selectedAddress.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.bluetooth_disabled,
                  color: Colors.grey),
              title: Text(printer.selectedName.isNotEmpty
                  ? printer.selectedName
                  : 'Printer'),
              subtitle: const Text('Belum terhubung'),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  await printer.loadSavedDevice();
                  _saveSettings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(printer.isConnected
                            ? 'Berhasil terhubung'
                            : 'Gagal terhubung'),
                        backgroundColor: printer.isConnected
                            ? const Color(0xFF2E7D32)
                            : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Hubungkan'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget? _printerSubtitle(PrinterProvider printer) {
    if (printer.connectionStatus == 'checking') {
      return const Text('Memeriksa...');
    }
    if (printer.selectedAddress.isEmpty) {
      return const Text('Ketuk untuk memilih printer');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          printer.selectedName.isNotEmpty
              ? printer.selectedName
              : printer.selectedAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          printer.connectionStatus == 'connected'
              ? 'Terhubung'
              : 'Belum terhubung',
          style: TextStyle(
            fontSize: 12,
            color: printer.connectionStatus == 'connected'
                ? const Color(0xFF2E7D32)
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showReceiptPreview(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Preview Struk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_logoFile != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                _logoFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            _namaTokoCtrl.text.isNotEmpty
                                ? _namaTokoCtrl.text
                                : 'Nama Toko',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_alamatCtrl.text.isNotEmpty)
                            Text(
                              _alamatCtrl.text,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          if (_noTelpCtrl.text.isNotEmpty)
                            Text(
                              'Telp: ${_noTelpCtrl.text}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          if (_alamatCtrl.text.isNotEmpty ||
                              _noTelpCtrl.text.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Divider(
                                  height: 1, color: Colors.grey.shade300),
                            ),
                          Text(
                            dateStr,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Divider(
                                height: 1, color: Colors.grey.shade300),
                          ),
                          _receiptItem('Indomie Goreng', '2 pcs', 'Rp5.000', 'Rp10.000'),
                          _receiptItem('Telur', '1 kg', 'Rp28.000', 'Rp28.000'),
                          _receiptItem('Sabun Botol', '1 pcs', 'Rp8.500', 'Rp8.500'),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Divider(
                                height: 1, color: Colors.grey.shade300),
                          ),
                          _receiptRow('TOTAL', 'Rp46.500', bold: true),
                          _receiptRow('BAYAR', 'Rp50.000'),
                          _receiptRow('KEMBALI', 'Rp3.500'),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Divider(
                                height: 1, color: Colors.grey.shade300),
                          ),
                          Text(
                            _sloganCtrl.text.isNotEmpty
                                ? _sloganCtrl.text
                                : 'Terima kasih!',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          if (_footerCtrl.text.isNotEmpty)
                            Text(
                              _footerCtrl.text,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _printTestFromPreview(context),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Preview'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printTestFromPreview(BuildContext context) async {
    final printer = context.read<PrinterProvider>();
    final sampleTransaksi = Transaksi(
      id: 'preview',
      items: [
        TransaksiItem(
            barangId: 'preview_1',
            nama: 'Indomie Goreng',
            harga: 5000,
            qty: 2,
            satuan: 'pcs'),
        TransaksiItem(
            barangId: 'preview_2',
            nama: 'Telur',
            harga: 28000,
            qty: 1,
            satuan: 'kg'),
        TransaksiItem(
            barangId: 'preview_3',
            nama: 'Sabun Botol',
            harga: 8500,
            qty: 1,
            satuan: 'pcs'),
      ],
      total: 46500,
      bayar: 50000,
      kembalian: 3500,
      timestamp: DateTime.now(),
    );
    final result = await printer.printStruk(sampleTransaksi);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Preview berhasil dicetak' : 'Gagal cetak. Pastikan printer terhubung.'),
          backgroundColor: result ? const Color(0xFF2E7D32) : Colors.red,
        ),
      );
    }
  }

  Widget _receiptRow(String left, String right, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              left,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptItem(String name, String qty, String unitPrice, String subtotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$qty x $unitPrice',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(subtotal, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerOutcome {
  final BtcDevice? device;
  final bool released;

  const _PickerOutcome(this.device) : released = false;
  const _PickerOutcome.released() : device = null, released = true;
}

class _BluetoothDevicePickerSheet extends StatefulWidget {
  final String savedAddress;
  final String savedName;

  const _BluetoothDevicePickerSheet({
    required this.savedAddress,
    required this.savedName,
  });

  @override
  State<_BluetoothDevicePickerSheet> createState() =>
      _BluetoothDevicePickerSheetState();
}

class _BluetoothDevicePickerSheetState
    extends State<_BluetoothDevicePickerSheet> {
  bool _loading = true;
  bool _scanning = false;
  String? _connectingAddress;
  bool? _savedConnected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final printer = context.read<PrinterProvider>();
    final hasPermission = await printer.checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Izin Bluetooth diperlukan. Aktifkan di pengaturan aplikasi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    await printer.loadBondedDevices();
    await _refreshSavedConnection();
    if (mounted) setState(() => _loading = false);
    await _scan();
  }

  Future<void> _refreshSavedConnection() async {
    if (widget.savedAddress.isEmpty) return;
    final printer = context.read<PrinterProvider>();
    final connected = await printer.isConnectedToDevice();
    if (mounted) setState(() => _savedConnected = connected);
  }

  Future<void> _scan() async {
    final printer = context.read<PrinterProvider>();
    final hasPermission = await printer.checkAndRequestPermissions();
    if (!hasPermission) return;
    setState(() => _scanning = true);
    await printer.scanDevices();
    if (mounted) setState(() => _scanning = false);
    await _refreshSavedConnection();
  }

  Future<void> _connect(BtcDevice device) async {
    setState(() => _connectingAddress = device.address);
    final printer = context.read<PrinterProvider>();
    final result =
        await printer.connect(device.address, device.name ?? 'Printer');
    if (!mounted) return;
    if (result) {
      Navigator.pop(context, _PickerOutcome(device));
    } else {
      setState(() => _connectingAddress = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal terhubung ke ${device.name ?? device.address}. Pastikan printer menyala & sudah dipairing.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;
    final printer = context.watch<PrinterProvider>();

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pilih Perangkat Bluetooth',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.savedAddress.isNotEmpty) ...[
                    _savedRow(printer),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    onPressed: _scanning ? null : _scan,
                    icon: _scanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: Text(_scanning
                        ? 'Mencari perangkat...'
                        : 'Cari Perangkat'),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      ),
                    )
                  else if (printer.devices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada perangkat. Pastikan Bluetooth menyala dan printer dalam keadaan discoverable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else ...[
                    const Text(
                      'Perangkat Bluetooth',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final device in printer.devices)
                      _deviceRow(device, printer),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedRow(PrinterProvider printer) {
    final checking = _savedConnected == null;
    final isConnected = _savedConnected == true;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (checking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isConnected
                  ? Icons.check_circle
                  : Icons.bluetooth_disabled,
              size: 18,
              color: isConnected
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.savedName.isNotEmpty
                      ? widget.savedName
                      : 'Printer terpilih',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.savedAddress,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (checking)
            const Text('Memeriksa...',
                style: TextStyle(fontSize: 12, color: Colors.grey))
          else if (isConnected)
            const Text('Terhubung',
                style: TextStyle(
                    fontSize: 12, color: Color(0xFF2E7D32)))
          else
            const Text('Belum terhubung',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextButton(
            onPressed: () => Navigator.pop(
                context, const _PickerOutcome.released()),
            child: const Text('Lepas',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _deviceRow(BtcDevice device, PrinterProvider printer) {
    final connecting = _connectingAddress == device.address;
    final isSaved = device.address == printer.selectedAddress;
    final isDeviceConnected =
        device.address == printer.connectedMac && printer.isConnected;

    return InkWell(
      onTap: connecting ? null : () => _connect(device),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: connecting
              ? const Color(0xFF1565C0).withValues(alpha: 0.05)
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isDeviceConnected
                  ? Icons.link
                  : Icons.bluetooth_searching,
              size: 18,
              color: isDeviceConnected
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    device.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (connecting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isDeviceConnected)
              const Text('Terhubung',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF2E7D32)))
            else if (isSaved)
              const Text('Tersimpan',
                  style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              const Text('Konek',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  )),
          ],
        ),
      ),
    );
  }
}
