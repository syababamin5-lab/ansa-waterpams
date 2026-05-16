import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showUsageChart(p);
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('Rincian Pemakaian Air'),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
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

      // Ambil 12 data terakhir
      final recentHistory = history.length > 12 
          ? history.sublist(history.length - 12) 
          : history;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Tren Pemakaian 12 Bulan Terakhir', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: recentHistory.isEmpty 
              ? const Center(child: Text('Belum ada riwayat pemakaian'))
              : BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int idx = value.toInt();
                            if (idx < 0 || idx >= recentHistory.length) return const SizedBox();
                            final date = DateTime.parse(recentHistory[idx]['tanggal_catat']);
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: recentHistory.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: (entry.value['pemakaian'] as num).toDouble(),
                            color: AppTheme.primaryColor,
                            width: 15,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showSnackBar("Gagal memuat grafik: $e");
    }
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
      padding: const EdgeInsets.only(bottom: 10),
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
