import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/recent_watch_manager.dart';
import '../utils/constants.dart';
import '../widgets/recent_anime_card.dart';
import '../widgets/tako_loading_indicator.dart';

class RecentListScreen extends StatefulWidget {
  const RecentListScreen({super.key});

  @override
  State<RecentListScreen> createState() => _RecentListScreenState();
}

class _RecentListScreenState extends State<RecentListScreen>
    with AutomaticKeepAliveClientMixin {
  final recentWatchManager = Get.find<RecentWatchManager>();
  late final Future<void> _recentFuture;

  @override
  void initState() {
    super.initState();
    _recentFuture = recentWatchManager.loadRecentAnimeFromDatabase();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<void>(
      future: _recentFuture,
      builder: (_, snapshot) => GetBuilder<RecentWatchManager>(
        builder: (_) {
          if (snapshot.connectionState != ConnectionState.done &&
              recentWatchManager.animeList.isEmpty) {
            return const TakoLoadingView(avoidBottomNavigation: true);
          }
          if (recentWatchManager.animeList.isEmpty) return _emptyState();

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 104),
            itemCount: recentWatchManager.animeList.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pick up where you left off',
                          style: TextStyle(color: tkMutedText, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('SWIPE LEFT TO REMOVE',
                          style: TextStyle(
                            color: tkCoral,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                );
              }
              final item = recentWatchManager.animeList[index - 1];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    color: tkCoral.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      const Icon(Icons.delete_outline_rounded, color: tkCoral),
                ),
                onDismissed: (_) async =>
                    await recentWatchManager.removeAnime(item.id),
                child: RecentAnimeCard(
                  id: item.id,
                  currentEp: item.currentEp,
                  epUrl: item.epUrl,
                  name: item.name,
                  imageUrl: item.imageUrl,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration:
                const BoxDecoration(color: tkDarkBlue, shape: BoxShape.circle),
            child: const Icon(Icons.playlist_add_rounded,
                color: tkCoral, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Nothing in your watchlist yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Start an episode and it will appear here.',
              style: TextStyle(color: tkMutedText, fontSize: 13)),
        ],
      ),
    );
  }
}
