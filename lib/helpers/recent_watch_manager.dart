import 'package:get/get.dart';
import '../database/recent_watch_anime_database.dart';
import '../models/recent_anime.dart';

class RecentWatchManager extends GetxController {
  List<RecentAnime> recentAnimes = [];

  List<RecentAnime> get animeList => [...recentAnimes.reversed];

  Future<void> getAllRecentAnimeFromDatabase() async {
    final result = await RecentWatchAnimeDatabase.instance.getAllRecentAnime();
    if (result != null) {
      recentAnimes = result;
    }
  }

  void addAnimeToRecent(RecentAnime anime) {
    for (var rm in recentAnimes) {
      if (rm.id == anime.id) {
        RecentWatchAnimeDatabase.instance.remove(anime.id);
      }
    }
    recentAnimes.removeWhere((rm) => (rm.id == anime.id));
    recentAnimes.add(anime);
    RecentWatchAnimeDatabase.instance.insert(anime);
    update();
  }

  void removeAnime(String id) {
    recentAnimes.removeWhere((rm) => rm.id == id);
    RecentWatchAnimeDatabase.instance.remove(id);
    update();
  }

  void removeAllAnime() {
    recentAnimes.clear();
    RecentWatchAnimeDatabase.instance.removeAll();
    update();
  }
}

