import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';

class TagihanScreen extends StatefulWidget {
  const TagihanScreen({super.key});

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _tagihanBelumBayar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final transaksi = await _supabaseService.getAllTransaksi();
      setState(() {
        _tagihanBelumBayar = transaksi.where((t) => t['status'] != 'LUNAS').toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    return "${formatter.format(amount)},-";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tagihan Belum Bayar'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _tagihanBelumBayar.isEmpty
              ? const Center(child: Text('Semua tagihan sudah lunas! 🎉'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _tagihanBelumBayar.length,
                  itemBuilder: (context, index) {
                    final t = _tagihanBelumBayar[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _showPaymentDialog(t),
                        title: Text(t['pelanggan']['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Pemakaian: ${t['pemakaian']} m³'),
                        trailing: Text(formatRupiah(t['total_bayar']), 
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proses Pembayaran'),
        content: Text('Selesaikan pembayaran untuk ${t['pelanggan']['nama']} sebesar ${formatRupiah(t['total_bayar'])}?'),
        actions: [
          TextButton(
            onPressed: () => _prosesBayar(t['id'], 'CASH'),
            child: const Text('💰 CASH'),
          ),
          ElevatedButton(
            onPressed: () => _prosesBayar(t['id'], 'BANK'),
            child: const Text('🏦 BANK'),
          ),
        ],
      ),
    );
  }

  void _prosesBayar(String id, String metode) async {
    Navigator.pop(context);
    try {
      await _supabaseService.updatePembayaran(id, metode);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil dibayar via $metode")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("GAGAL: Pastikan sudah jalankan SQL di Supabase!\n$e"),
        duration: const Duration(seconds: 5),
      ));
    }
  }
}
