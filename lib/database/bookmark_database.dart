import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bookmark.dart';

abstract interface class BookmarkStore {
  Future<void> insert(BookMark bookMark);
  Future<List<BookMark>> getAllBookMarks();
  Future<int> delete(String id);
}

class BookMarksDatabase implements BookmarkStore {
  BookMarksDatabase._privateConstructor({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  /// Creates an isolated store for tests or a separately managed database.
  factory BookMarksDatabase.withDatabaseFactory({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) =>
      BookMarksDatabase._privateConstructor(
        databaseFactory: databaseFactory,
        databasePath: databasePath,
      );

  static final BookMarksDatabase instance =
      BookMarksDatabase._privateConstructor();
  static Database? _database;
  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  Database? _testDatabase;

  final String tableBookmark = 'Bookmark';
  final String idCol = 'id';
  final String nameCol = 'name';
  final String imageUrlCol = 'imageUrl';
  final String animeUrlCol = 'animeUrl';
  final String createdAtCol = 'createdAt';
  final dbName = 'takobookmarks.db';
  final idType = 'TEXT NOT NULL';
  final textType = 'TEXT NOT NULL';

  Future<Database> get database async {
    if (_databaseFactory != null) {
      if (_testDatabase != null) return _testDatabase!;
      _testDatabase = await _initDatabase();
      return _testDatabase!;
    }
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = _databasePath ??
        join((await getApplicationDocumentsDirectory()).path, dbName);

    final options = OpenDatabaseOptions(
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
    if (_databaseFactory != null) {
      return _databaseFactory!.openDatabase(path, options: options);
    }
    return openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $tableBookmark(
      $idCol TEXT PRIMARY KEY,
      $nameCol $textType,
      $imageUrlCol $textType,
      $animeUrlCol $textType,
      $createdAtCol INTEGER NOT NULL DEFAULT 0)''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= 2) return;

    await db.transaction((transaction) async {
      await transaction.execute('''
        DELETE FROM $tableBookmark
        WHERE rowid NOT IN (
          SELECT MAX(rowid) FROM $tableBookmark GROUP BY $idCol
        )
      ''');
      await transaction.execute('''
        ALTER TABLE $tableBookmark
        ADD COLUMN $createdAtCol INTEGER NOT NULL DEFAULT 0
      ''');
      await transaction.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS bookmark_id_unique
        ON $tableBookmark($idCol)
      ''');
    });
  }

  @override
  Future<void> insert(BookMark bookMark) async {
    final db = await database;
    await db.insert(
      tableBookmark,
      bookMark.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<BookMark>> getAllBookMarks() async {
    final db = await database;
    final results = await db.query(
      tableBookmark,
      orderBy: '$createdAtCol ASC, rowid ASC',
    );
    return results.map((json) => BookMark.fromJson(json)).toList();
  }

  @override
  Future<int> delete(String id) async {
    final db = await database;
    return db.delete(
      tableBookmark,
      where: '$idCol == ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
