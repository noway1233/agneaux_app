import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'agneaux.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE brebis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zip TEXT UNIQUE,
        boucle TEXT,
        commentaire TEXT
      )
    ''');

    await db.execute('''
        CREATE TABLE agneaux (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          brebis_id INTEGER,
          annee INTEGER,
          zip TEXT,
          boucle TEXT,
          sexe TEXT,
          vivant INTEGER,
          commentaire TEXT,
          poids_vente REAL,
          acheteur TEXT,
          date_vente TEXT,
          FOREIGN KEY(brebis_id) REFERENCES brebis(id) ON DELETE CASCADE
        )
      ''');
  }
  // =========================
  // STATISTIQUES ANNUELLES
  // =========================

  Future<int> countBrebisAyantMisBas(int annee) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT brebis_id) as total
      FROM agneaux
      WHERE annee = ?
    ''', [annee]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAgneauxBySexe(int annee, String sexe) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM agneaux
      WHERE annee = ? AND sexe = ?
    ''', [annee, sexe]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAgneauxVivant(int annee) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM agneaux
      WHERE annee = ? AND vivant = 1
    ''', [annee]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAgneauxMort(int annee) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM agneaux
      WHERE annee = ? AND vivant = 0
    ''', [annee]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countTotalAgneaux(int annee) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM agneaux
      WHERE annee = ?
    ''', [annee]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> countTypePortee(int annee) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as nb_agneaux
      FROM agneaux
      WHERE annee = ?
      GROUP BY brebis_id
    ''', [annee]);

    int simple = 0;
    int doublee = 0;
    int triplePlus = 0;

    for (var row in result) {
      int nb = row['nb_agneaux'] as int;

      if (nb == 1) simple++;
      if (nb == 2) doublee++;
      if (nb >= 3) triplePlus++;
    }

    return {
      'simple': simple,
      'double': doublee,
      'triplePlus': triplePlus,
    };
  }  

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE brebis ADD COLUMN commentaire TEXT",
      );

      await db.execute(
        "ALTER TABLE agneaux ADD COLUMN poids_vente REAL",
      );

      await db.execute(
        "ALTER TABLE agneaux ADD COLUMN acheteur TEXT",
      );

      await db.execute(
        "ALTER TABLE agneaux ADD COLUMN date_vente TEXT",
      );
    }
  }

  // =========================
  // BREBIS
  // =========================

  Future<int> getOrCreateBrebis(String zip, String boucle, String commentaire) async {
    final db = await database;

    final existing = await db.query(
      'brebis',
      where: 'zip = ?',
      whereArgs: [zip],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('brebis', {
      'zip': zip,
      'boucle': boucle,
      'commentaire': commentaire,
    });
  }

  Future<Map<String, dynamic>?> getBrebisByZip(String zip) async {
    final db = await database;

    final result = await db.query(
      'brebis',
      where: 'zip = ?',
      whereArgs: [zip],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // =========================
  // AGNEAUX
  // =========================

  Future<List<Map<String, dynamic>>> getAgneauxByBrebisAndYear(
      int brebisId, int annee) async {
    final db = await database;

    return await db.query(
      'agneaux',
      where: 'brebis_id = ? AND annee = ?',
      whereArgs: [brebisId, annee],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertAgneau(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('agneaux', data);
  }

  Future<void> updateAgneau(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'agneaux',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllBrebis() async {
    final db = await database;
    return await db.query('brebis', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getAllAgneaux() async {
    final db = await database;
    return await db.query('agneaux', orderBy: 'annee DESC');
  }

  Future<void> updateBrebisCommentaire(
      int id, String commentaire) async {
    final db = await database;
    await db.update(
      'brebis',
      {'commentaire': commentaire},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getAgneauByZip(String zip) async {
    final db = await database;

    final result = await db.query(
      'agneaux',
      where: 'zip = ?',
      whereArgs: [zip],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getBrebisById(int id) async {
    final db = await database;

    final result = await db.query(
      'brebis',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAgneauxByBrebis(int brebisId) async {
    final db = await database;

    return await db.query(
      'agneaux',
      where: 'brebis_id = ?',
      whereArgs: [brebisId],
      orderBy: 'id ASC',
    );
  }

  Future<bool> tousAgneauxSortis(int brebisId) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as restant
      FROM agneaux
      WHERE brebis_id = ?
      AND vivant = 1
      AND date_vente IS NULL
    ''', [brebisId]);

    final restant = Sqflite.firstIntValue(result) ?? 0;

    return restant == 0;
  }

}  