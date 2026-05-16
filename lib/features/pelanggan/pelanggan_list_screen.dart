import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';

class PelangganListScreen extends StatefulWidget {
  const PelangganListScreen({super.key});

  @override
  State<PelangganListScreen> createState() => _PelangganListScreenState();
}

class _PelangganListScreenState extends State<PelangganListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _pelanggan = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshPelanggan();
  }

  void _refreshPelanggan() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getPelanggan();
      setState(() {
        _pelanggan = data;
      });
    } catch (e) {
      _showSnackBar("Gagal memuat data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text('Data Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPelanggan,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshPelanggan(),
              child: _pelanggan.isEmpty
                  ? const Center(child: Text('Belum ada data pelanggan'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _pelanggan.length,
                      itemBuilder: (context, index) {
                        final p = _pelanggan[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            onTap: () => _showPelangganDetail(p),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.person, color: AppTheme.primaryColor),
                            ),
                            title: Text(p['nama'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(p['alamat'] ?? '-'),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPelangganDetail(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Detail Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailItem('Nama', p['nama']),
            _detailItem('Alamat', p['alamat'] ?? '-'),
            _detailItem('WhatsApp', p['telepon'] ?? '-'),
            _detailItem('Meter Terakhir', '${p['meter_terakhir']} m³'),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showUsageChart(p);
                },
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Rincian Pemakaian Air', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(p),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditDialog(context, p: p);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showUsageChart(Map<String, dynamic> p) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final history = await _supabaseService.getTransaksiByPelanggan(p['id']);
      Navigator.pop(context); // Close loading

      // GROUPING DATA PER BULAN
      Map<String, Map<String, dynamic>> grouped = {};
      for (var t in history) {
        final date = DateTime.parse(t['tanggal_catat']);
        final key = DateFormat('yyyy-MM').format(date); // Key unik per bulan-tahun
        
        if (!grouped.containsKey(key)) {
          grouped[key] = {
            'tanggal_catat': t['tanggal_catat'],
            'pemakaian': 0.0,
            'total_bayar': 0.0,
            'meter_lalu': t['meter_lalu'],
            'meter_skrg': t['meter_skrg'],
          };
        }
        
        grouped[key]!['pemakaian'] += (t['pemakaian'] as num).toDouble();
        grouped[key]!['total_bayar'] += (t['total_bayar'] as num).toDouble();
        grouped[key]!['meter_skrg'] = t['meter_skrg']; // Update ke meteran terbaru bulan itu
      }

      // Sortir berdasarkan tanggal dan ambil 12 bulan terakhir
      var sortedKeys = grouped.keys.toList()..sort();
      var recentHistory = sortedKeys.map((k) => grouped[k]!).toList();
      if (recentHistory.length > 12) {
        recentHistory = recentHistory.sublist(recentHistory.length - 12);
      }

      bool isChartView = true;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Analisis Pemakaian', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.bar_chart, color: isChartView ? AppTheme.primaryColor : Colors.grey),
                          onPressed: () => setDialogState(() => isChartView = true),
                        ),
                        IconButton(
                          icon: Icon(Icons.list_alt, color: !isChartView ? AppTheme.primaryColor : Colors.grey),
                          onPressed: () => setDialogState(() => isChartView = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 350,
                child: recentHistory.isEmpty 
                  ? const Center(child: Text('Belum ada riwayat pemakaian'))
                  : isChartView 
                    ? _buildPremiumChart(recentHistory) 
                    : _buildNumericTable(recentHistory),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            );
          }
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Gagal memuat statistik: $e");
    }
  }

  Widget _buildPremiumChart(List<Map<String, dynamic>> data) {
    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  )
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx < 0 || idx >= data.length) return const SizedBox();
                      final date = DateTime.parse(data[idx]['tanggal_catat']);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), (entry.value['pemakaian'] as num).toDouble());
                  }).toList(),
                  isCurved: true,
                  gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)]),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor.withOpacity(0.3), AppTheme.primaryColor.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y} m³',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
        ),
        const SizedBox(height: 10),
        const Text('* Satuan dalam Meter Kubik (m³)', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
      ],
    );
  }

  Widget _buildNumericTable(List<Map<String, dynamic>> data) {
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = data[data.length - 1 - index]; // Reverse order
        final date = DateTime.parse(t['tanggal_catat']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 45,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(DateFormat('MMM').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                    Text(DateFormat('yy').format(date), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemakaian: ${t['pemakaian']} m³', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Meter: ${t['meter_lalu']} ➔ ${t['meter_skrg']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Text(formatRupiah(t['total_bayar']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        );
      },
    ).animate().fadeIn();
  }

  void _confirmDelete(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan?'),
        content: Text('Anda yakin ingin menghapus ${p['nama']}? Semua riwayat transaksinya juga mungkin akan bermasalah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await _supabaseService.deletePelanggan(p['id']);
              Navigator.pop(context); // Close confirm
              Navigator.pop(context); // Close detail
              _refreshPelanggan();
              _showSnackBar("Pelanggan berhasil dihapus");
            }, 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? p}) {
    final nameController = TextEditingController(text: p?['nama'] ?? '');
    final addressController = TextEditingController(text: p?['alamat'] ?? '');
    final phoneController = TextEditingController(text: p?['telepon'] ?? '');
    final meterController = TextEditingController(text: p?['meter_terakhir']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(p == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Alamat')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'No. WhatsApp (628...)'), keyboardType: TextInputType.phone),
              TextField(controller: meterController, decoration: const InputDecoration(labelText: 'Meteran Awal'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'nama': nameController.text,
                'alamat': addressController.text,
                'telepon': phoneController.text,
                'meter_terakhir': double.tryParse(meterController.text) ?? 0,
              };

              if (p == null) {
                await _supabaseService.insertPelanggan(data);
              } else {
                await _supabaseService.updatePelanggan(p['id'], data);
              }
              Navigator.pop(context);
              _refreshPelanggan();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
