import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/barang.dart';
import '../providers/barang_provider.dart';
import '../utils/formatters.dart';
import '../widgets/responsive_layout.dart';

const _beepChannel = MethodChannel('com.kasir_toko/beep');

class BarangScreen extends StatelessWidget {
  const BarangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _BarangMobile(),
      tablet: const _BarangTablet(),
    );
  }
}

class _BarangMobile extends StatelessWidget {
  const _BarangMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Barang'),
        centerTitle: false,
      ),
      body: const _BarangList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _BarangTablet extends StatelessWidget {
  const _BarangTablet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Barang'),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Barang', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          const Expanded(flex: 8, child: _BarangList()),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 2,
            child: _BarangFormPanel(
              onScan: () => _showAddDialogWithScan(context),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAddDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _BarangFormSheet(),
  );
}

void _showAddDialogWithScan(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _BarangFormSheet(openScanner: true),
  );
}

class _BarangList extends StatelessWidget {
  const _BarangList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BarangProvider>();
    final barang = provider.filteredBarang;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari barang...',
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => provider.searchQuery = v,
              ),
              if (provider.kategoris.length > 1)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: provider.kategoris.length,
                    itemBuilder: (context, index) {
                      final kat = provider.kategoris[index];
                      final selected = provider.filterKategori == kat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(kat,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey[700])),
                          selected: selected,
                          selectedColor: const Color(0xFF1565C0),
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) =>
                              provider.filterKategori = kat,
                          visualDensity: VisualDensity.compact,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Total: ${provider.totalBarang} barang',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        Expanded(
          child: barang.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        provider.searchQuery.isNotEmpty
                            ? 'Barang tidak ditemukan'
                            : 'Belum ada barang',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  itemCount: barang.length,
                  itemBuilder: (context, index) {
                    final b = barang[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.nama,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  formatRupiah(b.hargaJual),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${b.kode} | ${b.kategori} | Stok: ${b.stok} ${b.satuan}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.grey[600],
                            onPressed: () => _showEditDialog(context, b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red[400],
                            onPressed: () => _confirmDelete(context, b),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, Barang barang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BarangFormSheet(barang: barang),
    );
  }

  void _confirmDelete(BuildContext context, Barang barang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Hapus "${barang.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<BarangProvider>().hapusBarang(barang.id);
              Navigator.pop(context);
            },
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BarangFormPanel extends StatelessWidget {
  final VoidCallback onScan;
  const _BarangFormPanel({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 32, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'Pilih barang untuk diedit\natau tambah barang baru',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner, size: 14),
              label: const Text('Scan Barcode',
                  style: TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarangFormSheet extends StatefulWidget {
  final Barang? barang;
  final bool openScanner;
  const _BarangFormSheet({this.barang, this.openScanner = false});

  @override
  State<_BarangFormSheet> createState() => _BarangFormSheetState();
}

class _BarangFormSheetState extends State<_BarangFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kodeCtrl;
  late TextEditingController _namaCtrl;
  late TextEditingController _hargaBeliCtrl;
  late TextEditingController _hargaJualCtrl;
  late TextEditingController _stokCtrl;
  late TextEditingController _kategoriCtrl;
  String _satuan = 'pcs';
  bool _showScanner = false;
  MobileScannerController? _scannerController;
  bool _isProcessing = false;

  bool get isEdit => widget.barang != null;

  @override
  void initState() {
    super.initState();
    final b = widget.barang;
    _kodeCtrl = TextEditingController(text: b?.kode ?? '');
    _namaCtrl = TextEditingController(text: b?.nama ?? '');
    _hargaBeliCtrl =
        TextEditingController(text: b != null ? formatMoneyDisplay(b.hargaBeli.toInt().toString()) : '');
    _hargaJualCtrl =
        TextEditingController(text: b != null ? formatMoneyDisplay(b.hargaJual.toInt().toString()) : '');
    _stokCtrl =
        TextEditingController(text: b != null ? '${b.stok}' : '0');
    _kategoriCtrl =
        TextEditingController(text: b?.kategori ?? 'Umum');
    _satuan = b?.satuan ?? 'pcs';
    if (widget.openScanner && !isEdit) {
      _showScanner = true;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void dispose() {
    _kodeCtrl.dispose();
    _namaCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _hargaJualCtrl.dispose();
    _stokCtrl.dispose();
    _kategoriCtrl.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    );
    setState(() {
      _showScanner = true;
      _isProcessing = false;
    });
  }

  void _stopScanner() {
    setState(() {
      _showScanner = false;
    });
    _scannerController?.dispose();
    _scannerController = null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                      isEdit ? 'Edit Barang' : 'Tambah Barang',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 12),
              if (_showScanner) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController!,
                          onDetect: (capture) {
                            if (_isProcessing) return;
                            final barcode = capture.barcodes.first;
                            final code = barcode.rawValue;
                            if (code != null && code.isNotEmpty) {
                              _isProcessing = true;
                              HapticFeedback.heavyImpact();
                              _beepChannel.invokeMethod('beep');
                              final existing = context.read<BarangProvider>().cariByKode(code);
                              setState(() {
                                _kodeCtrl.text = code;
                                if (existing != null) {
                                  _namaCtrl.text = existing.nama;
                                  _hargaBeliCtrl.text = formatMoneyDisplay(existing.hargaBeli.toInt().toString());
                                  _hargaJualCtrl.text = formatMoneyDisplay(existing.hargaJual.toInt().toString());
                                  _stokCtrl.text = '${existing.stok}';
                                  _kategoriCtrl.text = existing.kategori;
                                }
                                _showScanner = false;
                              });
                              _scannerController?.dispose();
                              _scannerController = null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existing != null
                                        ? 'Barang "${existing.nama}" ditemukan — tinggal edit'
                                        : 'Barcode baru: $code',
                                  ),
                                  backgroundColor: existing != null
                                      ? const Color(0xFF1565C0)
                                      : const Color(0xFF2E7D32),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                              );
                            }
                          },
                        ),
                        Center(
                          child: Container(
                            width: 200,
                            height: 2,
                            color: Colors.red,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Arahkan ke barcode',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!_showScanner) ...[
                TextFormField(
                  controller: _kodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kode Barcode',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showScanner
                            ? Icons.keyboard
                            : Icons.qr_code_scanner,
                        size: 20,
                      ),
                      onPressed:
                          _showScanner ? _stopScanner : _startScanner,
                      tooltip: _showScanner
                          ? 'Ketik Manual'
                          : 'Scan Barcode',
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hargaBeliCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli (Modal)',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hargaJualCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stokCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _kategoriCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _satuan,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pcs', child: Text('Pcs (Buah)')),
                    DropdownMenuItem(value: 'kg', child: Text('Kg (Kilogram)')),
                    DropdownMenuItem(value: 'gram', child: Text('Gram')),
                    DropdownMenuItem(value: 'liter', child: Text('Liter')),
                    DropdownMenuItem(value: 'ml', child: Text('ML (Mililiter)')),
                    DropdownMenuItem(value: 'pack', child: Text('Pack')),
                    DropdownMenuItem(value: 'box', child: Text('Box')),
                    DropdownMenuItem(value: 'lusin', child: Text('Lusin')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _satuan = v);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _save,
                  child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Barang'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BarangProvider>();
    final kode = _kodeCtrl.text.trim();
    final nama = _namaCtrl.text.trim();
    final hargaBeli = parseRupiah(_hargaBeliCtrl.text);
    final hargaJual = parseRupiah(_hargaJualCtrl.text);
    final stok = int.tryParse(_stokCtrl.text) ?? 0;
    final kategori = _kategoriCtrl.text.trim();

    if (isEdit) {
      final updated = widget.barang!.copyWith(
        nama: nama,
        hargaBeli: hargaBeli,
        hargaJual: hargaJual,
        stok: stok,
        kategori: kategori,
        satuan: _satuan,
      );
      provider.updateBarang(widget.barang!.id, updated);
    } else {
      final existing = provider.cariByKode(kode);
      if (existing != null) {
        provider.updateBarang(
          existing.id,
          existing.copyWith(
            nama: nama,
            hargaBeli: hargaBeli,
            hargaJual: hargaJual,
            stok: stok,
            kategori: kategori,
            satuan: _satuan,
          ),
        );
      } else {
        provider.tambahBarang(Barang(
          id: provider.generateId(),
          kode: kode,
          nama: nama,
          hargaBeli: hargaBeli,
          hargaJual: hargaJual,
          stok: stok,
          kategori: kategori,
          satuan: _satuan,
        ));
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit ? 'Barang diperbarui' : 'Barang ditambahkan'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

String formatRupiahShort(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}jt';
  }
  return 'Rp${value.toInt()}';
}
