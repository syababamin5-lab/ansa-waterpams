import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';
import '../reports/pdf_service.dart';

class CatatMeterScreen extends StatefulWidget {
  const CatatMeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CatatMeterContent();
  }
}

class _CatatMeterContent extends StatefulWidget {
  const _CatatMeterContent();

  @override
  State<_CatatMeterContent> createState() => _CatatMeterContentState();
}

class _CatatMeterContentState extends State<_CatatMeterContent> {
  final SupabaseService _supabaseService = SupabaseService();
  final PdfService _pdfService = PdfService();
  
  List<Map<String, dynamic>> _pelanggan = [];
  Map<String, dynamic>? _selectedPelanggan;
  Map<String, dynamic>? _settings;
  final TextEditingController _meterBaruController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  String formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return "${formatter.format(amount)},-";
  }

  void _loadInitialData() async {
    try {
      final pelData = await _supabaseService.getPelanggan();
      final setData = await _supabaseService.getSettings();
      setState(() {
        _pelanggan = pelData;
        _settings = setData;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Pencatatan Meter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildDropdown(),
            
            if (_selectedPelanggan != null && _settings != null) ...[
              const SizedBox(height: 30),
              _buildDetailCard().animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 30),
              _buildInputSection().animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),
              _buildCalculationSummary().animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ] else if (_pelanggan.isEmpty && _isSaving == false) ...[
               const SizedBox(height: 100),
               const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: AppTheme.cardDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          hint: const Text('Cari nama warga...'),
          value: _selectedPelanggan,
          items: _pelanggan.map((p) {
            return DropdownMenuItem(value: p, child: Text(p['nama']));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedPelanggan = val;
              _meterBaruController.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          _infoRow('Nama Warga', _selectedPelanggan!['nama']),
          const Divider(height: 25),
          _infoRow('Meter Terakhir', '${_selectedPelanggan!['meter_terakhir']} m³', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Angka Meteran Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: _meterBaruController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.speed, color: AppTheme.primaryColor),
            suffixText: 'm³',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (val) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildCalculationSummary() {
    final meterBaru = double.tryParse(_meterBaruController.text) ?? 0;
    final meterLalu = (_selectedPelanggan!['meter_terakhir'] as num).toDouble();
    final pakai = meterBaru > meterLalu ? meterBaru - meterLalu : 0.0;
    final harga = (_settings!['harga_per_kubik'] as num).toDouble();
    final beban = (_settings!['biaya_beban'] as num).toDouble();
    final total = (pakai * harga) + beban;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(color: Colors.blue.shade50),
      child: Column(
        children: [
          _infoRow('Pemakaian ($pakai m³ x ${formatRupiah(harga)})', formatRupiah(pakai * harga)),
          const SizedBox(height: 10),
          _infoRow('Biaya Beban Tetap', formatRupiah(beban)),
          const Divider(height: 25, thickness: 2),
          _infoRow('TOTAL TAGIHAN', formatRupiah(total), isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isSaving ? null : _prosesSimpan,
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Simpan & Terbitkan Tagihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: isHighlight ? 18 : 14,
          color: isHighlight ? AppTheme.primaryColor : AppTheme.textPrimary
        )),
      ],
    );
  }

  void _prosesSimpan() async {
    final meterBaru = double.tryParse(_meterBaruController.text);
    final meterLalu = (_selectedPelanggan!['meter_terakhir'] as num).toDouble();
    
    if (meterBaru == null || meterBaru <= meterLalu) {
      _showSnack('Angka meter baru harus lebih besar dari sebelumnya!');
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      double pakai = meterBaru - meterLalu;
      double harga = (_settings!['harga_per_kubik'] as num).toDouble();
      double beban = (_settings!['biaya_beban'] as num).toDouble();
      double total = (pakai * harga) + beban;

      await _supabaseService.insertTransaksi({
        'id_pelanggan': _selectedPelanggan!['id'],
        'meter_lalu': meterLalu,
        'meter_skrg': meterBaru,
        'pemakaian': pakai,
        'tarif_per_kubik': harga,
        'total_bayar': total,
      });

      final transaksiData = {
        'nama': _selectedPelanggan!['nama'],
        'alamat': _selectedPelanggan!['alamat'],
        'meter_lalu': meterLalu,
        'meter_skrg': meterBaru,
        'pemakaian': pakai,
        'harga': harga,
        'beban': beban,
        'total': total,
        'tanggal': DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now()),
        'pamsimas': _settings!['nama_pamsimas'],
      };

      await _pdfService.generateAndShareInvoice(transaksiData);
      
      _showSnack('Berhasil! Menampilkan jendela PDF...');
      _loadInitialData();
      setState(() {
        _selectedPelanggan = null;
        _meterBaruController.clear();
      });
    } catch (e) {
      _showSnack('Gagal menyimpan: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
