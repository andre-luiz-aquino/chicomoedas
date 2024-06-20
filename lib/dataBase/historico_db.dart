import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'historico';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = await getDatabasesPath();
    final databasePath = join(path, 'chicomoedas.db');

    return await openDatabase(databasePath, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
        CREATE TABLE $tableName(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          valor REAL,
          moeda TEXT,
          data TEXT
        )
        ''');
        });
  }

  Future<void> insertHistorico(double valor, String moeda) async {
    final db = await database;
    await db.insert(tableName, {
      'valor': valor,
      'moeda': moeda,
      'data': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistorico() async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<void> deleteHistorico(int id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
