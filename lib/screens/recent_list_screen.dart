import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/recent_watch_manager.dart';
import '../utils/constants.dart';
import '../widgets/recent_anime_card.dart';

class RecentListScreen extends StatelessWidget {
  final recentWatchManager = Get.find<RecentWatchManager>();

  RecentListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: recentWatchManager.loadRecentAnimeFromDatabase(),
      builder: (_, snapshot) => GetBuilder<RecentWatchManager>(
        builder: (_) => ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(
            height: 20,
          ),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          itemCount: recentWatchManager.animeList.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: UniqueKey(),
              onDismissed: (_) {
                recentWatchManager
                    .removeAnime(recentWatchManager.animeList[index].id);
              },
              direction: DismissDirection.endToStart,
              background: const Icon(
                Icons.delete_rounded,
                color: tkGradientBlue,
              ),
              child: RecentAnimeCard(
                id: recentWatchManager.animeList[index].id,
                currentEp: recentWatchManager.animeList[index].currentEp,
                epUrl: recentWatchManager.animeList[index].epUrl,
                name: recentWatchManager.animeList[index].name,
                imageUrl: recentWatchManager.animeList[index].imageUrl,
                // animeUrl: recentWatchManager.animeList[index].animeUrl,
              ),
            );
          },
        ),
      ),
    );
  }
}
