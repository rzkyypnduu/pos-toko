import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/barang.dart';
import '../providers/barang_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/transaksi_provider.dart';
import '../utils/formatters.dart';
import '../widgets/responsive_layout.dart';

const _beepChannel = MethodChannel('com.kasir_toko/beep');

class KasirScreen extends StatelessWidget {
  const KasirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const _KasirMobile(),
      tablet: const _KasirTablet(),
    );
  }
}

class _KasirMobile extends StatelessWidget {
  const _KasirMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        centerTitle: false,
      ),
      body: _KasirBody(),
    );
  }
}

class _KasirTablet extends StatelessWidget {
  const _KasirTablet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        centerTitle: false,
      ),
      body: _KasirTabletBody(),
    );
  }
}

class _KasirBody extends StatefulWidget {
  @override
  State<_KasirBody> createState() => _KasirBodyState();
}

class _KasirBodyState extends State<_KasirBody> {
  bool _scannerEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: _ScannerPanel(
            key: const ValueKey('scanner_mobile'),
            enabled: _scannerEnabled,
            onToggle: () =>
                setState(() => _scannerEnabled = !_scannerEnabled),
          ),
        ),
        const Divider(height: 1),
        const Expanded(
          flex: 1,
          child: _CartPanel(),
        ),
      ],
    );
  }
}

class _KasirTabletBody extends StatefulWidget {
  @override
  State<_KasirTabletBody> createState() => _KasirTabletBodyState();
}

class _KasirTabletBodyState extends State<_KasirTabletBody> {
  bool _scannerEnabled = true;

  @override
  Widget build(BuildContext context) {
    if (!_scannerEnabled) {
      return _CartPanel(
        onEnableScanner: () => setState(() => _scannerEnabled = true),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 90,
          child: _ScannerPanel(
            key: const ValueKey('scanner_on'),
            enabled: true,
            onToggle: () =>
                setState(() => _scannerEnabled = false),
          ),
        ),
        const Divider(height: 1),
        const Expanded(
          flex: 1,
          child: _CartPanel(),
        ),
      ],
    );
  }
}

class _ScannerPanel extends StatefulWidget {
  final bool enabled;
  final VoidCallback onToggle;

  const _ScannerPanel({
    super.key,
    required this.enabled,
    required this.onToggle,
  });

  @override
  State<_ScannerPanel> createState() => _ScannerPanelState();
}

class _ScannerPanelState extends State<_ScannerPanel> {
  MobileScannerController? _controller;
  String _lastScanned = '';
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
      );
    }
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
      transaksiProvider.tambahKeKeranjang(barang.id, barang.nama);
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
    if (!widget.enabled) return _buildCollapsedBar();
    return _buildScannerView();
  }

  Widget _buildCollapsedBar() {
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.grey[400], size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Scanner nonaktif',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner,
                      color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Aktifkan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                        child:
                            CircularProgressIndicator(color: Colors.white),
                      ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 200,
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Arahkan ke barcode',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleButton(
                    icon: Icons.qr_code_scanner,
                    label: 'OFF',
                    color: const Color(0xFFC62828),
                    onTap: widget.onToggle,
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.flash_on,
                    onTap: () => _controller?.toggleTorch(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color? color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatefulWidget {
  final VoidCallback? onEnableScanner;

  const _CartPanel({this.onEnableScanner});

  @override
  State<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<_CartPanel> {
  final _bayarCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Barang> _searchResults = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _bayarCtrl.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final barangProvider = context.read<BarangProvider>();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      return;
    }
    final results = barangProvider.cariBarang(value.trim());
    setState(() {
      _searchResults = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _addBarang(Barang barang) {
    final cart = context.read<TransaksiProvider>();
    cart.tambahKeKeranjang(barang.id, barang.nama);
    _searchCtrl.clear();
    _focusNode.unfocus();
    setState(() {
      _searchResults = [];
      _showSuggestions = false;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${barang.nama} ditambahkan'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _submitSearch(String value) {
    if (value.isEmpty) return;
    final barangProvider = context.read<BarangProvider>();

    final results = barangProvider.cariBarang(value.trim());
    if (results.isNotEmpty) {
      _addBarang(results.first);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barang "$value" tidak ditemukan'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showQtyDialog(
      BuildContext context, TransaksiProvider cart, int index, double currentQty) {
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
          onSubmitted: (_) => _submitQty(context, cart, index, ctrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => _submitQty(context, cart, index, ctrl),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitQty(BuildContext context, TransaksiProvider cart, int index, TextEditingController ctrl) {
    final text = ctrl.text.replaceAll(',', '.');
    final qty = double.tryParse(text);
    if (qty != null && qty > 0) {
      cart.setQty(index, qty);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<TransaksiProvider>();
    final barangProvider = context.watch<BarangProvider>();
    final cartItems = cart.cartItems;
    final total = cart.cartTotal(barangProvider);
    final bayar = parseRupiah(_bayarCtrl.text);
    final kembalian = bayar - total;

    return Column(
      children: [
        if (widget.onEnableScanner != null)
          GestureDetector(
            onTap: widget.onEnableScanner,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF0F4F8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner,
                      color: Colors.grey[400], size: 16),
                  const SizedBox(width: 6),
                  Text('Scanner nonaktif',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text('Aktifkan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _submitSearch,
              ),
              if (_showSuggestions && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final b = _searchResults[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              const Color(0xFF1565C0).withValues(alpha: 0.08),
                          child: Text(
                            b.kategori[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0)),
                          ),
                        ),
                        title: Text(b.nama,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '${b.kode} | ${formatRupiah(b.hargaJual)} | Stok: ${b.stok}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.add_circle,
                            color: Color(0xFF1565C0), size: 20),
                        onTap: () => _addBarang(b),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Keranjang kosong',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan barcode atau cari barang',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final b = barangProvider.cariById(item.barangId) ??
                        Barang(
                            id: item.barangId, kode: '', nama: item.nama);
                    final harga = b.hargaJual;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                                Text(item.nama,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Text(formatRupiah(harga),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _QtyButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (item.qty > 1) {
                                      cart.kurangiQty(index);
                                    } else {
                                      cart.hapusDariKeranjang(index);
                                    }
                                  },
                                ),
                                GestureDetector(
                                  onTap: () => _showQtyDialog(context, cart, index, item.qty),
                                  child: Container(
                                    width: 44,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(formatQty(item.qty),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => cart.tambahQty(index),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatRupiah(harga * item.qty),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1565C0)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  const Text('Total:',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
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
                      backgroundColor:
                          const Color(0xFF1565C0).withValues(alpha: 0.08),
                      side: BorderSide.none,
                      onPressed: () {
                        _bayarCtrl.text = formatMoneyDisplay(total.toInt().toString());
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
      await barangProvider.kurangiStok(item.barangId, item.qty.round());
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[600]),
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

class _TransaksiBerhasilDialogState extends State<_TransaksiBerhasilDialog> {
  bool _printing = false;
  bool? _printResult;
  String? _printError;

  @override
  void initState() {
    super.initState();
    if (widget.autoPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cetakStruk());
    }
  }

  Future<void> _cetakStruk() async {
    setState(() {
      _printing = true;
      _printResult = null;
      _printError = null;
    });

    final result = await widget.printerProvider.printStruk(widget.transaksi);

    if (mounted) {
      setState(() {
        _printing = false;
        _printResult = result;
        if (!result) {
          _printError = widget.printerProvider.selectedAddress.isEmpty
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
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
                  color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
            ),
          ],
          if (_printError != null) ...[
            const SizedBox(height: 8),
            Text(
              _printError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
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
              child: CircularProgressIndicator(strokeWidth: 2),
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
