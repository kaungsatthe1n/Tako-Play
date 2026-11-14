import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/episode_watch_progress.dart';
import '../models/recent_anime.dart';

abstract interface class RecentAnimeStore {
  Future<List<RecentAnime>> getAllRecentAnime();
  Future<void> insert(RecentAnime anime);
  Future<int> remove(String id);
  Future<int> removeAll();
}

abstract interface class EpisodeProgressStore {
  Future<List<EpisodeWatchProgress>> getEpisodeProgressForAnime(String animeId);
  Future<void> saveEpisodeProgress(EpisodeWatchProgress progress);
}

class RecentWatchAnimeDatabase
    implements RecentAnimeStore, EpisodeProgressStore {
  RecentWatchAnimeDatabase._privateConstructor({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  /// Creates an isolated store for tests or a separately managed database.
  factory RecentWatchAnimeDatabase.withDatabaseFactory({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) =>
      RecentWatchAnimeDatabase._privateConstructor(
        databaseFactory: databaseFactory,
        databasePath: databasePath,
      );

  static final RecentWatchAnimeDatabase instance =
      RecentWatchAnimeDatabase._privateConstructor();

  Database? _database;
  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;

  final String tableName = 'RecentAnime';
  final String progressTableName = 'EpisodeWatchProgress';
  final String idCol = 'id';
  final String nameCol = 'name';
  final String epUrlCol = 'epUrl';
  final String currentEpCol = 'currentEp';
  final String imageUrlCol = 'imageUrl';
  final String watchedAtCol = 'watchedAt';
  final String animeUrlCol = 'animeUrl';

  final String type = 'TEXT NOT NULL';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = _databasePath ??
        join((await getApplicationDocumentsDirectory()).path, tableName);

    final options = OpenDatabaseOptions(
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
    if (_databaseFactory != null) {
      return _databaseFactory!.openDatabase(path, options: options);
    }
    return openDatabase(
      path,
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $tableName (
      $idCol TEXT PRIMARY KEY,
      $nameCol $type,
      $epUrlCol $type,
      $currentEpCol $type,
      $imageUrlCol $type,
      $watchedAtCol INTEGER NOT NULL,
      $animeUrlCol TEXT NOT NULL DEFAULT '')
    ''');
    await _createProgressTable(db);
  }

  Future<void> _createProgressTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $progressTableName (
        animeId TEXT NOT NULL,
        episodeUrl TEXT NOT NULL,
        episodeNumber TEXT NOT NULL,
        positionMillis INTEGER NOT NULL,
        durationMillis INTEGER NOT NULL,
        updatedAtMillis INTEGER NOT NULL,
        PRIMARY KEY (animeId, episodeUrl)
      )
    ''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    await db.transaction((transaction) async {
      if (oldVersion < 2) {
        await transaction.execute('''
        DELETE FROM $tableName
        WHERE rowid NOT IN (
          SELECT MAX(rowid) FROM $tableName GROUP BY $idCol
        )
      ''');
        await transaction.execute('''
        ALTER TABLE $tableName
        ADD COLUMN $watchedAtCol INTEGER NOT NULL DEFAULT 0
      ''');
        await transaction.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS recent_anime_id_unique
        ON $tableName($idCol)
      ''');
      }
      if (oldVersion < 3) {
        await transaction.execute('''
          ALTER TABLE $tableName
          ADD COLUMN $animeUrlCol TEXT NOT NULL DEFAULT ''
        ''');
      }
      if (oldVersion < 4) {
        await _createProgressTable(transaction);
      }
    });
  }

  @override
  Future<List<RecentAnime>> getAllRecentAnime() async {
    final db = await database;
    final result = await db.query(
      tableName,
      orderBy: '$watchedAtCol ASC, rowid ASC',
    );
    return result.map((json) => RecentAnime.fromJson(json)).toList();
  }

  @override
  Future<void> insert(RecentAnime anime) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        ...anime.toJson(),
        watchedAtCol: DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> remove(String id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$idCol == ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> removeAll() async {
    final db = await database;
    return await db.delete(
      tableName,
    );
  }

  @override
  Future<List<EpisodeWatchProgress>> getEpisodeProgressForAnime(
      String animeId) async {
    final db = await database;
    final rows = await db.query(
      progressTableName,
      where: 'animeId = ?',
      whereArgs: [animeId],
      orderBy: 'updatedAtMillis DESC',
    );
    return rows
        .map((row) => EpisodeWatchProgress.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeWatchProgress progress) async {
    final db = await database;
    await db.insert(
      progressTableName,
      progress.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
