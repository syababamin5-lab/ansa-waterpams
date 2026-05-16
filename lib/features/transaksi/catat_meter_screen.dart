import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      debugPrint("Error loading pelanggan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Meter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<Map<String, dynamic>>(
              hint: const Text('Pilih Pelanggan'),
              value: _selectedPelanggan,
              items: _pelanggan.map((p) => DropdownMenuItem(value: p, child: Text(p['nama']))).toList(),
              onChanged: (val) => setState(() => _selectedPelanggan = val),
            ),
            if (_selectedPelanggan != null) ...[
              Text('Meter Terakhir: ${_selectedPelanggan!['meter_terakhir']}'),
              TextField(controller: _meterBaruController, decoration: const InputDecoration(labelText: 'Meter Baru')),
              ElevatedButton(onPressed: _prosesSimpan, child: const Text('Simpan & Cetak')),
            ]
          ],
        ),
      ),
    );
  }

  void _prosesSimpan() async {
    final meterBaru = double.tryParse(_meterBaruController.text);
    if (meterBaru == null) return;

    double pemakaian = meterBaru - _selectedPelanggan!['meter_terakhir'];
    double total = pemakaian * 3000;

    await _supabaseService.insertTransaksi({
      'id_pelanggan': _selectedPelanggan!['id'],
      'meter_lalu': _selectedPelanggan!['meter_terakhir'],
      'meter_skrg': meterBaru,
      'pemakaian': pemakaian,
      'tarif_per_kubik': 3000,
      'total_bayar': total,
    });

    final transaksiData = {
      'nama': _selectedPelanggan!['nama'],
      'alamat': _selectedPelanggan!['alamat'],
      'meter_lalu': _selectedPelanggan!['meter_terakhir'],
      'meter_skrg': meterBaru,
      'pemakaian': pemakaian,
      'total': total,
      'tanggal': DateFormat('dd MMM yyyy').format(DateTime.now()),
    };

    await _pdfService.generateAndShareInvoice(transaksiData);
    _loadPelanggan();
    setState(() => _selectedPelanggan = null);
  }
}
