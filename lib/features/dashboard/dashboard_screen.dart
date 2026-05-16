import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  
  bool _isLoading = true;
  int _totalWarga = 0;
  double _totalPendapatan = 0;
  int _countSudahBayar = 0;
  double _belumBayar = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final settings = await _supabaseService.getSettings();
      final pelanggan = await _supabaseService.getPelanggan();
      final transaksi = await _supabaseService.getAllTransaksi();

      double pendapatan = 0;
      double hutang = 0;
      int lunasCount = 0;

      for (var t in transaksi) {
        double bayar = (t['total_bayar'] ?? 0).toDouble();
        if (t['status'] == 'LUNAS') {
          pendapatan += bayar;
          lunasCount++;
        } else {
          hutang += bayar;
        }
      }

      setState(() {
        _hargaController.text = settings['harga_per_kubik'].toString();
        _bebanController.text = settings['biaya_beban'].toString();
        _namaPamsimasController.text = settings['nama_pamsimas'] ?? '';
        
        _totalWarga = pelanggan.length;
        _totalPendapatan = pendapatan;
        _countSudahBayar = lunasCount;
        _belumBayar = hutang;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Statistik Real-time'),
                    const SizedBox(height: 15),
                    _buildStatsGrid(),
                    const SizedBox(height: 30),
                    _buildSectionTitle('Grafik Pemakaian (m³)'),
                    const SizedBox(height: 15),
                    _buildChart(),
                    const SizedBox(height: 30),
                    _buildSectionTitle('Pengaturan Global'),
                    const SizedBox(height: 15),
                    _buildSettingsForm(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        background: Container(
          decoration: AppTheme.gradientDecoration,
          child: const Center(child: Icon(Icons.water_drop, color: Colors.white, size: 40)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _buildStatCard('Total Warga', _totalWarga.toString(), Icons.group, Colors.blue),
        _buildStatCard('Total Pendapatan', formatRupiah(_totalPendapatan), Icons.monetization_on, Colors.purple),
        _buildStatCard('Sudah Bayar', '$_countSudahBayar Transaksi', Icons.check_circle, Colors.green),
        _buildStatCard('Belum Bayar', formatRupiah(_belumBayar), Icons.warning, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroupData(0, 5, Colors.blue),
            _makeGroupData(1, 8, Colors.blue),
            _makeGroupData(2, 4, Colors.blue),
            _makeGroupData(3, 10, AppTheme.primaryColor),
            _makeGroupData(4, 7, Colors.blue),
            _makeGroupData(5, 6, Colors.blue),
          ],
        ),
      ),
    );
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
  }
}
