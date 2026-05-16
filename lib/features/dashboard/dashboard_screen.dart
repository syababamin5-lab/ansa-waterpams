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
  List<Map<String, dynamic>> _chartData = [];
  DateTimeRange? _selectedDateRange;
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

      // Grouping untuk Grafik (Sama dengan logika Pelanggan tapi untuk ALL warga)
      Map<String, Map<String, dynamic>> grouped = {};
      
      for (var t in transaksi) {
        final date = DateTime.parse(t['tanggal_catat']);
        
        // Filter Tanggal
        if (_selectedDateRange != null) {
          if (date.isBefore(_selectedDateRange!.start) || 
              date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
            continue; // Skip data yang tidak masuk rentang
          }
        }

        // Logika statistik
        double bayar = (t['total_bayar'] ?? 0).toDouble();
        if (t['status'] == 'LUNAS') {
          pendapatan += bayar;
          lunasCount++;
        } else {
          hutang += bayar;
        }

        // Logika grouping grafik
        final key = DateFormat('yyyy-MM').format(date);
        
        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'tanggal': t['tanggal_catat'],
            'pemakaian': 0.0,
          };
        }
        grouped[key]!['pemakaian'] += (t['pemakaian'] as num).toDouble();
      }

      // Sortir grafik dan ambil 12 bln terakhir
      var sortedKeys = grouped.keys.toList()..sort();
      var finalChartData = sortedKeys.map((k) => grouped[k]!).toList();
      if (finalChartData.length > 12) {
        finalChartData = finalChartData.sublist(finalChartData.length - 12);
      }

      setState(() {
        _hargaController.text = settings['harga_per_kubik'].toString();
        _bebanController.text = settings['biaya_beban'].toString();
        _namaPamsimasController.text = settings['nama_pamsimas'] ?? '';
        
        _totalWarga = pelanggan.length;
        _totalPendapatan = pendapatan;
        _countSudahBayar = lunasCount;
        _belumBayar = hutang;
        _chartData = finalChartData;
        
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
                    _buildChartHeader(),
                    const SizedBox(height: 15),
                    _buildChart(),
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
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          onPressed: _showSettingsModal,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_namaPamsimasController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pengaturan Global', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildSettingsForm(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Grafik Pemakaian (m³)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        TextButton.icon(
          onPressed: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: _selectedDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.primaryColor,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (range != null) {
              setState(() {
                _selectedDateRange = range;
                _isLoading = true;
              });
              _loadAllData();
            }
          },
          icon: const Icon(Icons.date_range, size: 16),
          label: Text(
            _selectedDateRange == null 
              ? 'Semua Waktu' 
              : '${DateFormat('dd MMM yy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yy').format(_selectedDateRange!.end)}',
            style: const TextStyle(fontSize: 12),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _statCard('Total Warga', '$_totalWarga Orang', Icons.people_alt_rounded, const Color(0xFF4A90E2)),
        _statCard('Pendapatan', formatRupiah(_totalPendapatan), Icons.account_balance_wallet_rounded, const Color(0xFF00C853)),
        _statCard('Lunas', '$_countSudahBayar Tagihan', Icons.verified_rounded, const Color(0xFF00BFA5)),
        _statCard('Belum Bayar', formatRupiah(_belumBayar), Icons.warning_rounded, const Color(0xFFFF9100)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.withOpacity(0.3)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontSize: 12, 
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_chartData.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data pemakaian')));

    // Jika data cuma 1, tambahkan titik 0 di depannya agar grafik muncul garisnya
    List<FlSpot> spots = [];
    if (_chartData.length == 1) {
      spots.add(const FlSpot(-1, 0)); // Titik bayangan 0
      spots.add(FlSpot(0, (_chartData[0]['pemakaian'] as num).toDouble()));
    } else {
      spots = _chartData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), (entry.value['pemakaian'] as num).toDouble());
      }).toList();
    }

    // Hitung Max Y untuk skala yang pas
    double maxY = 0;
    for (var s in spots) { if (s.y > maxY) maxY = s.y; }
    maxY = maxY == 0 ? 10 : maxY * 1.3; // Tambah ruang 30% di atas

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(15, 25, 25, 10),
      decoration: AppTheme.cardDecoration,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 9, color: Colors.grey)),
              )
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1, // Agar label bulan tidak ganda
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= _chartData.length) return const SizedBox();
                  final date = DateTime.parse(_chartData[idx]['tanggal']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.5)]),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsForm() {
    return Column(
      children: [
        _inputSettings('Nama Pamsimas', _namaPamsimasController, Icons.business_rounded),
        const SizedBox(height: 16),
        _inputSettings('Harga per m³', _hargaController, Icons.payments_rounded, isNumber: true),
        const SizedBox(height: 16),
        _inputSettings('Biaya Beban Tetap', _bebanController, Icons.receipt_long_rounded, isNumber: true),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context); // Tutup modal saat klik simpan
              _updateSettings();
            },
            child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _showResetDataDialog,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Kosongkan Semua Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _showResetDataDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Hapus Semua Data?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tindakan ini akan menghapus SELURUH data pelanggan dan transaksi secara permanen. Anda tidak dapat mengembalikannya.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Masukkan Kode Keamanan',
                  prefixIcon: const Icon(Icons.lock_rounded, color: Colors.red),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (pinController.text == '229308') {
                  Navigator.pop(context); // Tutup pop-up
                  Navigator.pop(context); // Tutup pengaturan
                  setState(() => _isLoading = true);
                  try {
                    await _supabaseService.deleteAllData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil: Semua data telah dikosongkan!')));
                    _loadAllData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus data: $e')));
                    setState(() => _isLoading = false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode salah! Data aman.')));
                }
              },
              child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _inputSettings(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  void _updateSettings() async {
    try {
      await _supabaseService.updateSettings({
        'harga_per_kubik': double.parse(_hargaController.text),
        'biaya_beban': double.parse(_bebanController.text),
        'nama_pamsimas': _namaPamsimasController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan!')));
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }
}
