import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final settings = await _supabaseService.getSettings();
      setState(() {
        _hargaController.text = settings['harga_per_kubik'].toString();
        _bebanController.text = settings['biaya_beban'].toString();
        _namaPamsimasController.text = settings['nama_pamsimas'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Statistik Ringkas'),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Warga', '128', Icons.group, Colors.blue)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatCard('Tagihan', 'Rp 4.2M', Icons.receipt_long, Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 20),
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
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Ansa Water', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: AppTheme.gradientDecoration,
          child: const Center(child: Icon(Icons.water_drop, color: Colors.white, size: 50)),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 250,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan disimpan!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, color: color, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
  }
}
