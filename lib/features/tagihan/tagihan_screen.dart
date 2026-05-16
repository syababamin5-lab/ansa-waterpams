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
  Map<String, dynamic>? _currentSettings;
  
  String _filterType = 'Semua';
  bool _isLoading = true;
  DateTime _selectedPaymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final transaksi = await _supabaseService.getAllTransaksi();
      final settings = await _supabaseService.getSettings();
      setState(() {
        _currentSettings = settings;
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
                _buildSliverHeader('BELUM BAYAR (${_pendingTagihan.length})', Colors.red),
                _buildSliverList(_pendingTagihan, isLunas: false),
                _buildSliverHeader('SUDAH BAYAR (${_filteredLunas.length})', Colors.green),
                _buildSliverFilter(),
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
                onTap: () => isLunas ? _showDetailDialog(t) : _showPaymentDialog(t),
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
    final tglCatat = DateFormat('dd MMM yyyy').format(DateTime.parse(t['tanggal_catat']));
    _selectedPaymentDate = DateTime.now();

    // Fallback harga jika data lama (0)
    final harga = (t['harga_saat_ini'] ?? 0) > 0 ? t['harga_saat_ini'] : (_currentSettings?['harga_per_kubik'] ?? 0);
    final beban = (t['beban_saat_ini'] ?? 0) > 0 ? t['beban_saat_ini'] : (_currentSettings?['biaya_beban'] ?? 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Text('Konfirmasi Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Pelanggan', t['pelanggan']['nama']),
                _buildDetailRow('Periode', tglCatat),
                const Divider(),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedPaymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => _selectedPaymentDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tanggal Bayar:', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        Text(DateFormat('dd MMM yyyy').format(_selectedPaymentDate), 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildDetailRow('Meter Lalu', '${t['meter_lalu']} m³'),
                _buildDetailRow('Meter Baru', '${t['meter_skrg']} m³'),
                _buildDetailRow('Pemakaian', '${t['pemakaian']} m³'),
                _buildDetailRow('Harga/m³', formatRupiah(harga)),
                _buildDetailRow('Biaya Beban', formatRupiah(beban)),
                const Divider(),
                _buildDetailRow('Total Bayar', formatRupiah(t['total_bayar']), isBold: true, color: Colors.blue),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _prosesBayar(t['id'], 'CASH', _selectedPaymentDate),
                icon: const Icon(Icons.money),
                label: const Text('CASH'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                onPressed: () => _prosesBayar(t['id'], 'BANK', _selectedPaymentDate),
                icon: const Icon(Icons.account_balance, color: Colors.white),
                label: const Text('BANK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> t) {
    final tglCatat = DateFormat('dd MMM yyyy').format(DateTime.parse(t['tanggal_catat']));
    final tglBayar = t['tanggal_bayar'] != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(t['tanggal_bayar']))
        : '-';

    final harga = (t['harga_saat_ini'] ?? 0) > 0 ? t['harga_saat_ini'] : (_currentSettings?['harga_per_kubik'] ?? 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Pelanggan', t['pelanggan']['nama']),
            _buildDetailRow('Periode', tglCatat),
            _buildDetailRow('Status', 'LUNAS', color: Colors.green),
            _buildDetailRow('Metode', t['metode_bayar'] ?? '-'),
            _buildDetailRow('Tgl Bayar', tglBayar),
            const Divider(),
            _buildDetailRow('Pemakaian', '${t['pemakaian']} m³'),
            _buildDetailRow('Harga/m³', formatRupiah(harga)),
            _buildDetailRow('Total Bayar', formatRupiah(t['total_bayar']), isBold: true, color: Colors.green),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black,
            fontSize: 13,
          )),
        ],
      ),
    );
  }

  void _prosesBayar(String id, String metode, DateTime tgl) async {
    Navigator.pop(context);
    try {
      await _supabaseService.updatePembayaranWithDate(id, metode, tgl);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil dibayar via $metode")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }
}
