import 'package:get/get.dart';

import '../database/bookmark_database.dart';
import '../models/bookmark.dart';

/// [BookMarkManager] provides a way of managing and keeping track of user's
/// favourite shows by bookmarking them. All bookmarks are stored locally
/// on-device.
class BookMarkManager extends GetxController {
  BookMarkManager({BookmarkStore? database})
      : _database = database ?? BookMarksDatabase.instance;

  final BookmarkStore _database;

  /// List of all stored bookmark
  List<BookMark> _list = [];

  /// List of all bookmark ids
  List<String> _idList = [];

  List<BookMark> get bookMarks => [..._list];

  List<String> get ids => [..._idList];

  /// Loads all locally stored bookmarks from the bookmarks database
  Future<void> loadBookMarksFromDatabase() async {
    final dataList = await _database.getAllBookMarks();
    _idList = [];
    _list = dataList;
    for (final bookMark in _list) {
      _idList.add(bookMark.id);
    }
    update();
  }

  /// Creates a new bookmark
  Future<void> addToBookMarks(BookMark item) async {
    if (_idList.contains(item.id)) return;
    await _database.insert(item);
    _list.add(item);
    _idList.add(item.id);
    update();
  }

  /// Removes an existing bookmark
  Future<void> removeFromBookMarks(BookMark item) async {
    await _database.delete(item.id);
    _list.removeWhere((element) => element.id == item.id);
    _idList.remove(item.id);
    update();
  }
}
