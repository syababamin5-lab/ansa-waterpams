import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/db_helper.dart';

class PelangganListScreen extends StatefulWidget {
  const PelangganListScreen({super.key});

  @override
  State<PelangganListScreen> createState() => _PelangganListScreenState();
}

class _PelangganListScreenState extends State<PelangganListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _pelanggan = [];

  @override
  void initState() {
    super.initState();
    _refreshPelanggan();
  }

  void _refreshPelanggan() async {
    final data = await _dbHelper.getPelanggan();
    setState(() {
      _pelanggan = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Data Pelanggan'),
      ),
      body: _pelanggan.isEmpty
          ? const Center(child: Text('Belum ada data pelanggan'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _pelanggan.length,
              itemBuilder: (context, index) {
                final p = _pelanggan[index];
                return Card(
                  child: ListTile(
                    title: Text(p['nama']),
                    subtitle: Text(p['alamat']),
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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Alamat')),
            TextField(controller: meterController, decoration: const InputDecoration(labelText: 'Meter Awal')),
            ElevatedButton(
              onPressed: () async {
                await _dbHelper.insertPelanggan({
                  'nama': nameController.text,
                  'alamat': addressController.text,
                  'meter_awal': double.tryParse(meterController.text) ?? 0,
                  'meter_terakhir': double.tryParse(meterController.text) ?? 0,
                });
                Navigator.pop(context);
                _refreshPelanggan();
              },
              child: const Text('Simpan'),
            )
          ],
        ),
      ),
    );
  }
}
