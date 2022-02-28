import 'package:get/get.dart';

import '../database/bookmark_database.dart';
import '../models/bookmark.dart';

/// [BookMarkManager] provides a way of managing and keeping track of user's
/// favourite shows by bookmarking them. All bookmarks are stored locally
/// on-device.
class BookMarkManager extends GetxController {
  /// List of all stored bookmark
  List<BookMark> _list = [];

  /// List of all bookmark ids
  List<String> _idList = [];

  List<BookMark> get bookMarks => [..._list];

  List<String> get ids => [..._idList];

  /// Loads all locally stored bookmarks from the bookmarks database
  Future<void> loadBookMarksFromDatabase() async {
    final dataList = await BookMarksDatabase.instance.getAllBookMarks();
    if (dataList != null) {
      _list = dataList;
      for (var bookMark in _list) {
        _idList.add(bookMark.id);
      }
    } else {
      _list = [];
      _idList = [];
    }
  }

  /// Creates a new bookmark
  void addToBookMarks(BookMark item) {
    _list.add(item);
    _idList.add(item.id);
    BookMarksDatabase.instance.insert(item);
    update();
  }

  /// Removes an existing bookmark
  void removeFromBookMarks(BookMark item) {
    _list.removeWhere((element) => element.id == item.id);
    _idList.remove(item.id);
    BookMarksDatabase.instance.delete(item.id);
    update();
  }
}
