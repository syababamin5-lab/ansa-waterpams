import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _hargaController = TextEditingController();
  final _bebanController = TextEditingController();
  final _namaPamsimasController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    try {
      final data = await _supabaseService.getSettings();
      setState(() {
        _hargaController.text = data['harga_per_kubik'].toString();
        _bebanController.text = data['biaya_beban'].toString();
        _namaPamsimasController.text = data['nama_pamsimas'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Pengaturan Biaya')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildInputCard('Nama PAMSIMAS', _namaPamsimasController, Icons.business),
                  const SizedBox(height: 20),
                  _buildInputCard('Harga per m³ (Rp)', _hargaController, Icons.water_drop, isNumber: true),
                  const SizedBox(height: 20),
                  _buildInputCard('Biaya Beban Tetap (Rp)', _bebanController, Icons.account_balance_wallet, isNumber: true),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _saveSettings,
                      child: const Text('Simpan Pengaturan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengaturan berhasil disimpan!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal simpan: $e")));
    }
  }
}
