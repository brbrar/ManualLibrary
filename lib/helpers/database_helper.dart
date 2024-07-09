import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('manuals.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE manuals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        isFavourite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertManual(Map<String, dynamic> manual) async {
    final db = await instance.database;
    return await db.insert('manuals', manual);
  }

  Future<List<Map<String, dynamic>>> getManuals() async {
    final db = await instance.database;
    return await db.query('manuals');
  }

  Future<int> deleteManual(int id) async {
    final db = await instance.database;
    return await db.delete('manuals', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateManual(Map<String, dynamic> manual) async {
    final db = await instance.database;
    return await db.update(
      'manuals',
      manual,
      where: 'id = ?',
      whereArgs: [manual['id']],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
