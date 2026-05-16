import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';
import '../reports/pdf_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final PdfService _pdfService = PdfService();
  List<Map<String, dynamic>> _riwayat = [];
  Map<String, dynamic>? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final data = await _supabaseService.getAllTransaksi();
      final settings = await _supabaseService.getSettings();
      setState(() {
        _riwayat = data;
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return "${formatter.format(amount)},-";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _riwayat.isEmpty
              ? const Center(child: Text('Belum ada transaksi'))
              : RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _riwayat.length,
                    itemBuilder: (context, index) {
                      final t = _riwayat[index];
                      final date = DateTime.parse(t['tanggal_catat']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          onTap: () => _showDetailPopup(t),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                          ),
                          title: Text(t['pelanggan']['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatRupiah(t['total_bayar']), 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              Text('${t['pemakaian']} m³', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showDetailPopup(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Detail Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Nama', t['pelanggan']['nama']),
            _detailRow('WhatsApp', t['pelanggan']['telepon'] ?? '-'),
            _detailRow('Tanggal', DateFormat('dd MMMM yyyy').format(DateTime.parse(t['tanggal_catat']))),
            const Divider(),
            _detailRow('Meter Lalu', '${t['meter_lalu']} m³'),
            _detailRow('Meter Baru', '${t['meter_skrg']} m³'),
            _detailRow('Pemakaian', '${t['pemakaian']} m³'),
            const Divider(),
            _detailRow('Total Bayar', formatRupiah(t['total_bayar']), isBold: true),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
               Navigator.pop(context);
               _cetakPdf(t);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            label: const Text('Cetak', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
               Navigator.pop(context);
               _kirimWhatsApp(t);
            },
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _cetakPdf(Map<String, dynamic> t) async {
    final data = {
      'nama': t['pelanggan']['nama'],
      'alamat': t['pelanggan']['alamat'],
      'meter_lalu': t['meter_lalu'],
      'meter_skrg': t['meter_skrg'],
      'pemakaian': t['pemakaian'],
      'harga': t['tarif_per_kubik'],
      'beban': t['total_bayar'] - (t['pemakaian'] * t['tarif_per_kubik']),
      'total': t['total_bayar'],
      'tanggal': DateFormat('dd MMMM yyyy').format(DateTime.parse(t['tanggal_catat'])),
      'pamsimas': _settings?['nama_pamsimas'] ?? 'ANSA WATER',
    };
    await _pdfService.generateAndShareInvoice(data);
  }

  void _kirimWhatsApp(Map<String, dynamic> t) async {
    setState(() => _isLoading = true);
    
    try {
      final latestPelanggan = await _supabaseService.getPelangganById(t['id_pelanggan']);
      final nama = latestPelanggan['nama'];
      final phone = latestPelanggan['telepon']?.toString() ?? '';
      
      if (phone.isEmpty || phone == '-') {
        _showSnack("Nomor WA warga ini belum diisi!");
        return;
      }

      // Membuat Struk Digital Teks yang Rapi
      final total = formatRupiah(t['total_bayar']);
      final pemakaian = t['pemakaian'];
      final pamsimas = (_settings?['nama_pamsimas'] ?? 'ANSA WATER').toUpperCase();
      final tgl = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(t['tanggal_catat']));
      final meterLalu = t['meter_lalu'];
      final meterSkrg = t['meter_skrg'];

      final data = {
        'nama': nama,
        'alamat': latestPelanggan['alamat'],
        'meter_lalu': meterLalu,
        'meter_skrg': meterSkrg,
        'pemakaian': pemakaian,
        'harga': t['tarif_per_kubik'],
        'beban': t['total_bayar'] - (pemakaian * t['tarif_per_kubik']),
        'total': t['total_bayar'],
        'tanggal': DateFormat('dd MMMM yyyy').format(DateTime.parse(t['tanggal_catat'])),
        'pamsimas': pamsimas,
      };

      String strukDigital = 
          "━━━━━━━━━━━━━━━\n"
          "     *STRUK TAGIHAN AIR*     \n"
          "        *$pamsimas*        \n"
          "━━━━━━━━━━━━━━━\n"
          "Pelanggan : *$nama*\n"
          "Tanggal   : $tgl\n"
          "━━━━━━━━━━━━━━━\n"
          "Meter Lalu: $meterLalu m³\n"
          "Meter Baru: $meterSkrg m³\n"
          "Pemakaian : *$pemakaian m³*\n"
          "━━━━━━━━━━━━━━━\n"
          "TOTAL BAYAR:\n"
          "👉 *${total}*\n"
          "━━━━━━━━━━━━━━━\n"
          "Simpan struk ini sebagai\nbukti pembayaran sah.\n"
          "Terima kasih.";

      String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.startsWith('0')) cleanPhone = '62${cleanPhone.substring(1)}';
      else if (cleanPhone.startsWith('8')) cleanPhone = '62$cleanPhone';

      final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(strukDigital)}";
      
      // Buka WA (Sekali klik langsung terkirim di Web/HP)
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      // Tetap download PDF sebagai cadangan/arsip jika diperlukan
      await _pdfService.shareInvoice(data);

    } catch (e) {
      _showSnack("Gagal memproses struk: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
