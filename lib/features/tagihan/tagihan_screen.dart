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
  List<Map<String, dynamic>> _allTagihan = [];
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
        _allTagihan = transaksi;
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
        title: const Text('Kelola Tagihan'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _allTagihan.isEmpty
              ? const Center(child: Text('Belum ada data transaksi.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _allTagihan.length,
                  itemBuilder: (context, index) {
                    final t = _allTagihan[index];
                    final isLunas = t['status'] == 'LUNAS';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLunas ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        onTap: isLunas ? null : () => _showPaymentDialog(t),
                        leading: CircleAvatar(
                          backgroundColor: isLunas ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(
                            isLunas ? Icons.check_circle : Icons.pending_actions,
                            color: isLunas ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(t['pelanggan']['nama'], style: const TextStyle(fontWeight: FontWeight.bold))),
                            _buildStatusBadge(isLunas),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text('Pemakaian: ${t['pemakaian']} m³', style: const TextStyle(fontSize: 12)),
                            if (isLunas) Text('Metode: ${t['metode_bayar'] ?? '-'}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        trailing: Text(
                          formatRupiah(t['total_bayar']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLunas ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusBadge(bool isLunas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLunas ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLunas ? 'LUNAS' : 'PENDING',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Proses Pembayaran'),
        content: Text('Selesaikan pembayaran untuk ${t['pelanggan']['nama']} sebesar ${formatRupiah(t['total_bayar'])}?'),
        actions: [
          TextButton(
            onPressed: () => _prosesBayar(t['id'], 'CASH'),
            child: const Text('💰 CASH'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => _prosesBayar(t['id'], 'BANK'),
            child: const Text('🏦 BANK', style: TextStyle(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }
}
