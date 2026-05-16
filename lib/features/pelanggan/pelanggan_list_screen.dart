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
          ],
        ),
        actions: [
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
            label: const Text('Edit Data'),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? p}) {
    final nameController = TextEditingController(text: p?['nama']);
    final addressController = TextEditingController(text: p?['alamat']);
    final phoneController = TextEditingController(text: p?['telepon']);
    final meterController = TextEditingController(text: p?['meter_awal']?.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p == null ? 'Tambah Pelanggan' : 'Edit Pelanggan', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Pelanggan')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Alamat')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Nomor WhatsApp (Contoh: 0812...)')),
            if (p == null) 
              TextField(controller: meterController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meter Awal')),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    if (nameController.text.isEmpty) {
                      _showSnackBar("Nama harus diisi!");
                      return;
                    }
                    
                    if (p == null) {
                      await _supabaseService.insertPelanggan(
                        nameController.text,
                        addressController.text,
                        phoneController.text,
                        double.tryParse(meterController.text) ?? 0,
                      );
                    } else {
                      await _supabaseService.updatePelanggan(p['id'], {
                        'nama': nameController.text,
                        'alamat': addressController.text,
                        'telepon': phoneController.text,
                      });
                    }
                    
                    Navigator.pop(context);
                    _refreshPelanggan();
                    _showSnackBar("Data berhasil disimpan!");
                  } catch (e) {
                    _showSnackBar("Error: $e");
                  }
                },
                child: const Text('Simpan Perubahan'),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
