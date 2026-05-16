import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';
import '../reports/pdf_service.dart';

class CatatMeterScreen extends StatefulWidget {
  const CatatMeterScreen({super.key});

  @override
  State<CatatMeterScreen> createState() => _CatatMeterScreenState();
}

class _CatatMeterScreenState extends State<CatatMeterScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final PdfService _pdfService = PdfService();
  
  List<Map<String, dynamic>> _pelanggan = [];
  Map<String, dynamic>? _selectedPelanggan;
  final TextEditingController _meterBaruController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPelanggan();
  }

  void _loadPelanggan() async {
    try {
      final data = await _supabaseService.getPelanggan();
      setState(() {
        _pelanggan = data;
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
            
            if (_selectedPelanggan != null) ...[
              const SizedBox(height: 30),
              _buildDetailCard().animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 30),
              _buildInputSection().animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ] else ...[
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    const Text('Pilih warga untuk mulai mencatat', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
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
          _infoRow('Alamat', _selectedPelanggan!['alamat'] ?? '-'),
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
            hintText: '0.0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (val) => setState(() {}),
        ),
      ],
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
          elevation: 5,
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
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
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
    if (meterBaru == null || meterBaru <= _selectedPelanggan!['meter_terakhir']) {
      _showSnack('Angka meter baru harus lebih besar dari sebelumnya!');
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      double pemakaian = meterBaru - _selectedPelanggan!['meter_terakhir'];
      double tarif = 3000;
      double total = pemakaian * tarif;

      await _supabaseService.insertTransaksi({
        'id_pelanggan': _selectedPelanggan!['id'],
        'meter_lalu': _selectedPelanggan!['meter_terakhir'],
        'meter_skrg': meterBaru,
        'pemakaian': pemakaian,
        'tarif_per_kubik': tarif,
        'total_bayar': total,
      });

      final transaksiData = {
        'nama': _selectedPelanggan!['nama'],
        'alamat': _selectedPelanggan!['alamat'],
        'meter_lalu': _selectedPelanggan!['meter_terakhir'],
        'meter_skrg': meterBaru,
        'pemakaian': pemakaian,
        'total': total,
        'tanggal': DateFormat('dd MMMM yyyy').format(DateTime.now()),
      };

      await _pdfService.generateAndShareInvoice(transaksiData);
      
      _showSnack('Berhasil! PDF Tagihan sedang dibuka...');
      _loadPelanggan();
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
