import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/barang.dart';
import '../providers/barang_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/transaksi_provider.dart';
import '../utils/formatters.dart';

const _beepChannel = MethodChannel('com.kasir_toko/beep');

class KasirScreen extends StatelessWidget {
  const KasirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _KasirBody();
  }
}

class _KasirBody extends StatefulWidget {
  const _KasirBody();

  @override
  State<_KasirBody> createState() => _KasirBodyState();
}

class _KasirBodyState extends State<_KasirBody> {
  bool _scannerEnabled = false;
  Offset _scannerPosition = const Offset(20, 200);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _scannerEnabled = !_scannerEnabled),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _scannerEnabled
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 18,
                      color: _scannerEnabled ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _scannerEnabled ? 'Scan Aktif' : 'Scan Barcode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _scannerEnabled ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _CartPanel(),
          if (_scannerEnabled)
            Positioned(
              left: _scannerPosition.dx,
              top: _scannerPosition.dy,
              child: _FloatingScanner(
                onToggle: () =>
                    setState(() => _scannerEnabled = false),
                onMove: (Offset delta) {
                  setState(() {
                    _scannerPosition = Offset(
                      (_scannerPosition.dx + delta.dx).clamp(
                          0.0,
                          MediaQuery.of(context).size.width - 200),
                      (_scannerPosition.dy + delta.dy).clamp(
                          0.0,
                          MediaQuery.of(context).size.height - 280),
                    );
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingScanner extends StatefulWidget {
  final VoidCallback onToggle;
  final ValueChanged<Offset> onMove;

  const _FloatingScanner({required this.onToggle, required this.onMove});

  @override
  State<_FloatingScanner> createState() => _FloatingScannerState();
}

class _FloatingScannerState extends State<_FloatingScanner> {
  MobileScannerController? _controller;
  String _lastScanned = '';
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String code) {
    final now = DateTime.now();
    if (code == _lastScanned &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 2) {
      return;
    }

    _lastScanned = code;
    _lastScanTime = now;
    HapticFeedback.heavyImpact();
    _beepChannel.invokeMethod('beep');

    final barangProvider = context.read<BarangProvider>();
    final transaksiProvider = context.read<TransaksiProvider>();
    final barang = barangProvider.cariByKode(code);

    if (barang != null) {
      transaksiProvider.tambahKeKeranjang(barang.id, barang.nama, satuan: barang.satuan);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${barang.nama} ditambahkan'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode "$code" tidak ditemukan'),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => widget.onMove(d.delta),
      child: Container(
        width: 200,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _controller != null
                  ? MobileScanner(
                      controller: _controller!,
                      onDetect: (capture) {
                        final barcode = capture.barcodes.first;
                        final code = barcode.rawValue;
                        if (code != null) _onBarcodeDetected(code);
                      },
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 140,
                  height: 2,
                  color: const Color(0xFFC62828),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Geser untuk pindah',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: widget.onToggle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _controller?.toggleTorch(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatefulWidget {
  const _CartPanel();

  @override
  State<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<_CartPanel> {
  final _bayarCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String _filterKategori = 'Semua';

  @override
  void dispose() {
    _bayarCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showQtyDialog(TransaksiProvider cart, int index, double currentQty) {
    final ctrl = TextEditingController(text: formatQty(currentQty));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Jumlah', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '0',
          ),
          onSubmitted: (_) => _submitQty(cart, index, ctrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => _submitQty(cart, index, ctrl),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitQty(TransaksiProvider cart, int index, TextEditingController ctrl) {
    final text = ctrl.text.replaceAll(',', '.');
    final qty = double.tryParse(text);
    if (qty != null && qty > 0) {
      cart.setQty(index, qty);
    }
    Navigator.pop(context);
  }

  List<Barang> _getFilteredBarangs(
      BarangProvider barangProvider, List cartItems) {
    var list = barangProvider.barangList;
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((b) =>
              b.nama.toLowerCase().contains(query) ||
              b.kode.toLowerCase().contains(query))
          .toList();
    }
    if (_filterKategori != 'Semua') {
      list = list.where((b) => b.kategori == _filterKategori).toList();
    }
    final inCartIds = cartItems.map((c) => c.barangId).toSet();
    final inCart = list.where((b) => inCartIds.contains(b.id)).toList();
    final notInCart = list.where((b) => !inCartIds.contains(b.id)).toList();
    return [...inCart, ...notInCart];
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<TransaksiProvider>();
    final barangProvider = context.watch<BarangProvider>();
    final cartItems = cart.cartItems;
    final total = cart.cartTotal(barangProvider);
    final bayar = parseRupiah(_bayarCtrl.text);
    final kembalian = bayar - total;
    final filteredBarangs = _getFilteredBarangs(barangProvider, cartItems);
    final kategoris = barangProvider.kategoris;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
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
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (kategoris.length > 1)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: kategoris.length,
              itemBuilder: (context, index) {
                final kat = kategoris[index];
                final selected = _filterKategori == kat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(kat,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                selected ? Colors.white : Colors.grey[700])),
                    selected: selected,
                    selectedColor: const Color(0xFF1565C0),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (_) =>
                        setState(() => _filterKategori = kat),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: filteredBarangs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('Tidak ada barang',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Tambah barang di menu Kelola Barang',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  itemCount: filteredBarangs.length,
                  itemBuilder: (context, index) {
                    final b = filteredBarangs[index];
                    final inCart = cartItems.any((c) => c.barangId == b.id);
                    final cartItem = inCart
                        ? cartItems.firstWhere((c) => c.barangId == b.id)
                        : null;
                    final cartIndex = inCart
                        ? cartItems.indexOf(cartItem!)
                        : -1;

                    return GestureDetector(
                      onTap: inCart
                          ? null
                          : () {
                              cart.tambahKeKeranjang(b.id, b.nama, satuan: b.satuan);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${b.nama} ditambahkan'),
                                  backgroundColor: const Color(0xFF2E7D32),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            },
                      child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: inCart
                            ? const Color(0xFF1565C0)
                                .withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: inCart
                              ? const Color(0xFF1565C0)
                                  .withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
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
                                  '${b.kode} | Stok: ${formatQty(b.stok)} ${b.satuan}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          if (inCart && cartItem != null) ...[
                            _QtyButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (cartItem.qty > 1) {
                                  cart.kurangiQty(cartIndex);
                                } else {
                                  cart.hapusDariKeranjang(cartIndex);
                                }
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => _showQtyDialog(cart, cartIndex, cartItem.qty),
                                child: Container(
                                  width: 40,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                      formatQty(cartItem.qty),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add,
                              onTap: () => cart.tambahQty(cartIndex),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  cart.hapusDariKeranjang(cartIndex),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red[400]),
                              ),
                            ),
                          ] else
                            GestureDetector(
                              onTap: () {
                                cart.tambahKeKeranjang(b.id, b.nama, satuan: b.satuan);
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${b.nama} ditambahkan'),
                                    backgroundColor: const Color(0xFF2E7D32),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              },
                              child: const Icon(Icons.add_circle,
                                  color: Color(0xFF1565C0), size: 22),
                            ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total (${formatQty(cartItems.fold<double>(0, (s, c) => s + (c.satuan == 'kg' || c.satuan == 'gram' || c.satuan == 'liter' || c.satuan == 'ml' ? 1.0 : c.qty)))} qty):',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(formatRupiah(total),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bayarCtrl,
                      inputFormatters: [RupiahInputFormatter()],
                      decoration: InputDecoration(
                        hintText: 'Bayar',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (total > 0)
                    ActionChip(
                      label: const Text('Uang Pas',
                          style: TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.paid, size: 16),
                      backgroundColor: const Color(0xFF1565C0)
                          .withValues(alpha: 0.08),
                      side: BorderSide.none,
                      onPressed: () {
                        _bayarCtrl.text = formatMoneyDisplay(
                            total.toInt().toString());
                        setState(() {});
                      },
                      visualDensity: VisualDensity.compact,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
              if (bayar >= total && total > 0) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Kembali: ${formatRupiah(kembalian)}',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      (cartItems.isNotEmpty && bayar >= total && total > 0)
                          ? () => _prosesBayar(context, total, bayar)
                          : null,
                  icon: const Icon(Icons.payment),
                  label: const Text('Bayar & Cetak Struk'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _prosesBayar(BuildContext context, double total, double bayar) async {
    final cart = context.read<TransaksiProvider>();
    final barangProvider = context.read<BarangProvider>();
    final printerProvider = context.read<PrinterProvider>();

    final barangMap = <String, Barang>{};
    for (final b in barangProvider.barangList) {
      barangMap[b.id] = b;
    }

    final transaksi = await cart.prosesTransaksi(
      cartItems: List.from(cart.cartItems),
      bayar: bayar,
      barangMap: barangMap,
    );

    for (final item in transaksi.items) {
      await barangProvider.kurangiStok(item.barangId, item.qty);
    }

    cart.clearCart();
    _bayarCtrl.clear();
    setState(() {});

    if (context.mounted) {
      final autoPrint = printerProvider.autoPrint;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TransaksiBerhasilDialog(
          transaksi: transaksi,
          printerProvider: printerProvider,
          autoPrint: autoPrint,
        ),
      );
    }
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
    );
  }
}

class _TransaksiBerhasilDialog extends StatefulWidget {
  final dynamic transaksi;
  final PrinterProvider printerProvider;
  final bool autoPrint;

  const _TransaksiBerhasilDialog({
    required this.transaksi,
    required this.printerProvider,
    this.autoPrint = false,
  });

  @override
  State<_TransaksiBerhasilDialog> createState() =>
      _TransaksiBerhasilDialogState();
}

class _TransaksiBerhasilDialogState
    extends State<_TransaksiBerhasilDialog> {
  bool _printing = false;
  bool? _printResult;
  String? _printError;

  @override
  void initState() {
    super.initState();
    if (widget.autoPrint) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _cetakStruk());
    }
  }

  Future<void> _cetakStruk() async {
    setState(() {
      _printing = true;
      _printResult = null;
      _printError = null;
    });

    final result =
        await widget.printerProvider.printStruk(widget.transaksi);

    if (mounted) {
      setState(() {
        _printing = false;
        _printResult = result;
        if (!result) {
          _printError =
              widget.printerProvider.selectedAddress.isEmpty
                  ? 'Printer belum dipilih. Atur di menu Pengaturan.'
                  : 'Gagal cetak struk. Pastikan printer menyala & terhubung.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaksi = widget.transaksi;

    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle,
                color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Transaksi Berhasil'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: #${transaksi.id}'),
          const SizedBox(height: 4),
          Text('Total: ${formatRupiah(transaksi.total)}'),
          Text('Bayar: ${formatRupiah(transaksi.bayar)}'),
          Text('Kembali: ${formatRupiah(transaksi.kembalian)}'),
          if (_printResult == true) ...[
            const SizedBox(height: 8),
            const Text(
              'Struk berhasil dicetak',
              style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold),
            ),
          ],
          if (_printError != null) ...[
            const SizedBox(height: 8),
            Text(
              _printError!,
              style: const TextStyle(
                  color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        if (_printing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_printResult != true)
          TextButton.icon(
            onPressed: _cetakStruk,
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Cetak Struk'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
