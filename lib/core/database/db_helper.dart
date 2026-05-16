import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ansa_water.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table Pelanggan
    await db.execute('''
      CREATE TABLE pelanggan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        alamat TEXT,
        telepon TEXT,
        meter_awal REAL DEFAULT 0,
        meter_terakhir REAL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pelanggan INTEGER,
        meter_lalu REAL,
        meter_skrg REAL,
        pemakaian REAL,
        tarif_per_kubik REAL,
        total_bayar REAL,
        status_bayar TEXT DEFAULT 'Belum Lunas',
        tanggal_catat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_pelanggan) REFERENCES pelanggan (id)
      )
    ''');
  }

  // --- CRUD Pelanggan ---
  Future<int> insertPelanggan(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pelanggan', data);
  }

  Future<List<Map<String, dynamic>>> getPelanggan() async {
    final db = await database;
    return await db.query('pelanggan', orderBy: 'nama ASC');
  }

  // --- CRUD Transaksi ---
  Future<int> insertTransaksi(Map<String, dynamic> data) async {
    final db = await database;
    // Update meter_terakhir di tabel pelanggan juga
    await db.update(
      'pelanggan',
      {'meter_terakhir': data['meter_skrg']},
      where: 'id = ?',
      whereArgs: [data['id_pelanggan']],
    );
    return await db.insert('transaksi', data);
  }

  Future<List<Map<String, dynamic>>> getRiwayatTransaksi(int idPelanggan) async {
    final db = await database;
    return await db.query(
      'transaksi',
      where: 'id_pelanggan = ?',
      whereArgs: [idPelanggan],
      orderBy: 'tanggal_catat DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransaksi() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, p.nama as nama_pelanggan 
      FROM transaksi t 
      JOIN pelanggan p ON t.id_pelanggan = p.id 
      ORDER BY t.tanggal_catat DESC
    ''');
  }
}
