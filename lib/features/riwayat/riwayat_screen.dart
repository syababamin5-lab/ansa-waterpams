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
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
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
            onPressed: () => _cetakPdf(t),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            label: const Text('Cetak', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _kirimWhatsApp(t),
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
    final nama = t['pelanggan']['nama'];
    final total = formatRupiah(t['total_bayar']);
    final pemakaian = t['pemakaian'];
    final pamsimas = _settings?['nama_pamsimas'] ?? 'ANSA WATER';
    final tgl = DateFormat('dd/MM/yyyy').format(DateTime.parse(t['tanggal_catat']));

    String pesan = "Halo Bapak/Ibu *$nama*,\n\n"
        "Ini adalah rincian tagihan air *$pamsimas* Anda untuk periode $tgl:\n"
        "- Pemakaian: $pemakaian m³\n"
        "- Total Tagihan: *$total*\n\n"
        "Mohon segera melakukan pembayaran. Terima kasih.";

    final phone = t['pelanggan']['telepon'] ?? '';
    // Hapus karakter non-angka
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(pesan)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
    }
  }
}
