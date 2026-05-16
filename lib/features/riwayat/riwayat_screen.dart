import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  void _loadRiwayat() async {
    try {
      final data = await _supabaseService.getAllTransaksi();
      setState(() {
        _riwayat = data;
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
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _riwayat.length,
                  itemBuilder: (context, index) {
                    final t = _riwayat[index];
                    final date = DateTime.parse(t['tanggal_catat']);
                    return Card(
                      margin: const EdgeInsets.bottom(15),
                      child: ListTile(
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
    );
  }
}
