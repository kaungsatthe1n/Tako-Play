import 'package:flutter/foundation.dart';
import '../database/bookmark_database.dart';

class BookMark {
  String id;
  String name;
  String animeUrl;
  String imageUrl;

  BookMark(
      {required this.id,
      required this.name,
      required this.animeUrl,
      required this.imageUrl});

  factory BookMark.fromJson(Map<String, dynamic> json) => BookMark(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        animeUrl: json['animeUrl'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'animeUrl': animeUrl,
      };
}

class BookMarkProvider extends ChangeNotifier {
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
    notifyListeners();
  }

  void removeFromBookMarks(BookMark item) {
    list.removeWhere((element) => element.id == item.id);
    idList.remove(item.id);
    BookMarksDatabase.instance.delete(item.id);
    notifyListeners();
  }
}
