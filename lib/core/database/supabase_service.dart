import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // --- CRUD Pelanggan ---
  Future<List<Map<String, dynamic>>> getPelanggan() async {
    final response = await client
        .from('pelanggan')
        .select()
        .order('nama', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertPelanggan(String nama, String alamat, String telepon, double meterAwal) async {
    await client.from('pelanggan').insert({
      'nama': nama,
      'alamat': alamat,
      'telepon': telepon,
      'meter_awal': meterAwal,
      'meter_terakhir': meterAwal,
    });
  }

  // --- CRUD Transaksi ---
  Future<void> insertTransaksi(Map<String, dynamic> data) async {
    // 1. Simpan Transaksi
    await client.from('transaksi').insert(data);
    
    // 2. Update Meter Terakhir di Tabel Pelanggan
    await client
        .from('pelanggan')
        .update({'meter_terakhir': data['meter_skrg']})
        .eq('id', data['id_pelanggan']);
  }

  Future<List<Map<String, dynamic>>> getAllTransaksi() async {
    final response = await client
        .from('transaksi')
        .select('*, pelanggan(nama)')
        .order('tanggal_catat', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
