import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Data Pelanggan')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _pelanggan.isEmpty
              ? const Center(child: Text('Belum ada data pelanggan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _pelanggan.length,
                  itemBuilder: (context, index) {
                    final p = _pelanggan[index];
                    return Card(
                      child: ListTile(
                        title: Text(p['nama'] ?? 'Tanpa Nama'),
                        subtitle: Text(p['alamat'] ?? '-'),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPelangganDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPelangganDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final meterController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tambah Pelanggan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Alamat')),
            TextField(controller: meterController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meter Awal')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    if (nameController.text.isEmpty) {
                      _showSnackBar("Nama harus diisi!");
                      return;
                    }
                    await _supabaseService.insertPelanggan(
                      nameController.text,
                      addressController.text,
                      "", 
                      double.tryParse(meterController.text) ?? 0,
                    );
                    Navigator.pop(context);
                    _refreshPelanggan();
                    _showSnackBar("Data berhasil disimpan ke Cloud!");
                  } catch (e) {
                    _showSnackBar("Error Simpan: $e");
                  }
                },
                child: const Text('Simpan Ke Cloud'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
