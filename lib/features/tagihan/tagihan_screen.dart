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
  List<Map<String, dynamic>> _pendingTagihan = [];
  List<Map<String, dynamic>> _lunasTagihan = [];
  List<Map<String, dynamic>> _filteredLunas = [];
  
  String _filterType = 'Semua'; // Semua, Minggu, Bulan
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
        _pendingTagihan = transaksi.where((t) => t['status'] != 'LUNAS').toList();
        _lunasTagihan = transaksi.where((t) => t['status'] == 'LUNAS').toList();
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    setState(() {
      if (_filterType == 'Minggu') {
        _filteredLunas = _lunasTagihan.where((t) {
          final date = DateTime.parse(t['tanggal_catat']);
          return now.difference(date).inDays <= 7;
        }).toList();
      } else if (_filterType == 'Bulan') {
        _filteredLunas = _lunasTagihan.where((t) {
          final date = DateTime.parse(t['tanggal_catat']);
          return date.month == now.month && date.year == now.year;
        }).toList();
      } else {
        _filteredLunas = List.from(_lunasTagihan);
      }
    });
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
          : CustomScrollView(
              slivers: [
                // SEKSI BELUM BAYAR
                _buildSliverHeader('BELUM BAYAR (${_pendingTagihan.length})', Colors.red),
                _buildSliverList(_pendingTagihan, isLunas: false),

                // DIVIDER & FILTER SEKSI LUNAS
                _buildSliverHeader('SUDAH BAYAR (${_filteredLunas.length})', Colors.green),
                _buildSliverFilter(),
                
                // SEKSI SUDAH BAYAR
                _buildSliverList(_filteredLunas, isLunas: true),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildSliverHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
        child: Row(
          children: [
            Container(width: 4, height: 20, color: color),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverFilter() {
    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: ['Semua', 'Minggu', 'Bulan'].map((type) {
            final isSelected = _filterType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type == 'Semua' ? 'Semua Waktu' : '$type Ini'),
                selected: isSelected,
                selectedColor: Colors.green.withOpacity(0.2),
                labelStyle: TextStyle(color: isSelected ? Colors.green : Colors.grey, fontSize: 12),
                onSelected: (val) {
                  if (val) {
                    setState(() => _filterType = type);
                    _applyFilter();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSliverList(List<Map<String, dynamic>> list, {required bool isLunas}) {
    if (list.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final t = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isLunas ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
              ),
              child: ListTile(
                onTap: isLunas ? null : () => _showPaymentDialog(t),
                leading: Icon(isLunas ? Icons.check_circle : Icons.pending, color: isLunas ? Colors.green : Colors.red),
                title: Text(t['pelanggan']['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Pakai: ${t['pemakaian']} m³ ${isLunas ? '(${t['metode_bayar']})' : ''}', style: const TextStyle(fontSize: 11)),
                trailing: Text(formatRupiah(t['total_bayar']), 
                    style: TextStyle(fontWeight: FontWeight.bold, color: isLunas ? Colors.green : Colors.red)),
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Bayar'),
        content: Text('Pelanggan: ${t['pelanggan']['nama']}\nTotal: ${formatRupiah(t['total_bayar'])}'),
        actions: [
          TextButton(onPressed: () => _prosesBayar(t['id'], 'CASH'), child: const Text('💰 CASH')),
          ElevatedButton(onPressed: () => _prosesBayar(t['id'], 'BANK'), child: const Text('🏦 BANK')),
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
