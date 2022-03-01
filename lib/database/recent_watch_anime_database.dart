import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/recent_anime.dart';

class RecentWatchAnimeDatabase {
  RecentWatchAnimeDatabase._privateConstructor();

  static final RecentWatchAnimeDatabase instance =
      RecentWatchAnimeDatabase._privateConstructor();

  Database? _database;

  final String tableName = 'RecentAnime';
  final String idCol = 'id';
  final String nameCol = 'name';
  final String epUrlCol = 'epUrl';
  final String currentEpCol = 'currentEp';
  final String imageUrlCol = 'imageUrl';
  // final String animeUrlCol = 'animeUrl';

  final String type = 'TEXT NOT NULL';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, tableName);

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future _createDatabase(Database db, version) async {
    await db.execute('''
    CREATE TABLE $tableName (
      $idCol $type, $nameCol $type, $epUrlCol $type, $currentEpCol $type, $imageUrlCol $type)
    ''');
  }

  Future<List<RecentAnime>>? getAllRecentAnime() async {
    final db = await instance.database;
    final result = await db.query(tableName);
    return result.map((json) => RecentAnime.fromJson(json)).toList();
  }

  Future<void> insert(RecentAnime anime) async {
    final db = await instance.database;
    final result = await db.insert(tableName, anime.toJson());
    if (result != -1) {
      // ignore: avoid_print
      print('success');
    }
  }

  Future<int> remove(String id) async {
    final db = await instance.database;
    return await db.delete(
      tableName,
      where: '$idCol == ?',
      whereArgs: [id],
    );
  }

  Future<int> removeAll() async {
    final db = await instance.database;
    return await db.delete(
      tableName,
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
