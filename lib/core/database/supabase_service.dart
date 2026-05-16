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

  Future<Map<String, dynamic>> getPelangganById(String id) async {
    final response = await client.from('pelanggan').select().eq('id', id).single();
    return Map<String, dynamic>.from(response);
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

  Future<void> updatePelanggan(String id, Map<String, dynamic> data) async {
    await client.from('pelanggan').update(data).eq('id', id);
  }

  Future<void> deletePelanggan(String id) async {
    await client.from('pelanggan').delete().eq('id', id);
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
        .select('*, pelanggan(*)')
        .order('tanggal_catat', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updatePembayaran(String id, String metode) async {
    await client.from('transaksi').update({
      'status': 'LUNAS',
      'metode_bayar': metode,
      'tanggal_bayar': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // --- CRUD Pengaturan ---
  Future<Map<String, dynamic>> getSettings() async {
    final response = await client.from('pengaturan').select().single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await client.from('pengaturan').update(data).eq('id', 1);
  }
}
