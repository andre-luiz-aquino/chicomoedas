import 'package:chicomoedas/dto/usuario_dto.dart';
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
    String path = join(await getDatabasesPath(), 'usuarios.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
            '''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nomeUsuario TEXT UNIQUE,
            nomeCompleto TEXT,
            email TEXT,
            senha TEXT,
            isLogado INTEGER
          )
          '''
        );
      },
    );
  }

  Future<void> insertUsuario(Usuario usuario) async {
    final db = await database;
    await db.insert(
      'usuarios',
      usuario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Usuario?> getUsuario(String nomeUsuario) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'nomeUsuario = ?',
      whereArgs: [nomeUsuario],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Usuario?> getLogado() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'isLogado = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> updateLogado(String nomeUsuario, bool isLogado) async {
    final db = await database;
    await db.update(
      'usuarios',
      {'isLogado': isLogado ? 1 : 0},
      where: 'nomeUsuario = ?',
      whereArgs: [nomeUsuario],
    );
  }
}