import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _hargaController = TextEditingController();
  final _bebanController = TextEditingController();
  final _namaPamsimasController = TextEditingController();
  
  List<Map<String, dynamic>> _tagihanBelumBayar = [];
  bool _isLoading = true;
  double _totalTagihan = 0;
  int _totalPelanggan = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final settings = await _supabaseService.getSettings();
      final transaksi = await _supabaseService.getAllTransaksi();
      final pelanggan = await _supabaseService.getPelanggan();

      setState(() {
        _hargaController.text = settings['harga_per_kubik'].toString();
        _bebanController.text = settings['biaya_beban'].toString();
        _namaPamsimasController.text = settings['nama_pamsimas'] ?? '';
        
        // Filter yang belum bayar
        _tagihanBelumBayar = transaksi.where((t) => t['status'] != 'LUNAS').toList();
        
        // Hitung Total Tagihan Belum Bayar
        _totalTagihan = _tagihanBelumBayar.fold(0, (sum, item) => sum + (item['total_bayar'] ?? 0));
        _totalPelanggan = pelanggan.length;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStats(),
                      const SizedBox(height: 25),
                      _buildSectionHeader('Tagihan Belum Bayar', Icons.receipt_long),
                      const SizedBox(height: 10),
                      _buildTagihanList(),
                      const SizedBox(height: 30),
                      _buildSectionHeader('Pengaturan Global', Icons.settings),
                      const SizedBox(height: 15),
                      _buildSettingsForm(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_namaPamsimasController.text.isEmpty ? 'ANSA WATER' : _namaPamsimasController.text, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        background: Container(decoration: AppTheme.gradientDecoration),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Pelanggan', _totalPelanggan.toString(), Icons.people, Colors.blue)),
        const SizedBox(width: 15),
        Expanded(child: _buildStatCard('Belum Bayar', formatRupiah(_totalTagihan), Icons.account_balance_wallet, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTagihanList() {
    if (_tagihanBelumBayar.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: const Center(child: Text('Semua tagihan lunas! 🎉')),
      );
    }

    return Column(
      children: _tagihanBelumBayar.map((t) => _buildTagihanCard(t)).toList(),
    );
  }

  Widget _buildTagihanCard(Map<String, dynamic> t) {
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
      _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil dibayar via $metode")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  Widget _buildSettingsForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          TextField(controller: _namaPamsimasController, decoration: const InputDecoration(labelText: 'Nama PAMSIMAS')),
          TextField(controller: _hargaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga / m³')),
          TextField(controller: _bebanController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Biaya Beban')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Simpan Pengaturan'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    try {
      await _supabaseService.updateSettings({
        'harga_per_kubik': double.parse(_hargaController.text),
        'biaya_beban': double.parse(_bebanController.text),
        'nama_pamsimas': _namaPamsimasController.text,
      });
      _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan disimpan!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }
}
