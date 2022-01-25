import 'package:get/get.dart';
import '../database/bookmark_database.dart';
import '../models/bookmark.dart';

class BookMarkManager extends GetxController {
  List<BookMark> list = [];
  List<String> idList = [];

  Future<void> getAllBookMarkFromDatabase() async {
    final dataList = await BookMarksDatabase.instance.getAllBookMarks();
    if (dataList != null) {
      list = dataList;
      for (var bookMark in list) {
        idList.add(bookMark.id);
      }
    } else {
      list = [];
      idList = [];
    }
  }

  List<BookMark> get bookMarks => [...list];

  List<String> get ids => [...idList];

  void addToBookMarks(BookMark item) {
    list.add(item);
    idList.add(item.id);
    BookMarksDatabase.instance.insert(item);
    update();
  }

  void removeFromBookMarks(BookMark item) {
    list.removeWhere((element) => element.id == item.id);
    idList.remove(item.id);
    BookMarksDatabase.instance.delete(item.id);
    update();
  }
}
