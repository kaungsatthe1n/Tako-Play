import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/cache_image_with_cachemanager.dart';
import '../widgets/tako_loading_indicator.dart';

class BookMarksScreen extends StatefulWidget {
  const BookMarksScreen({super.key});

  @override
  State<BookMarksScreen> createState() => _BookMarksScreenState();
}

class _BookMarksScreenState extends State<BookMarksScreen>
    with AutomaticKeepAliveClientMixin {
  final bookmarkManager = Get.find<BookMarkManager>();
  late final Future<void> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = bookmarkManager.loadBookMarksFromDatabase();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<void>(
      future: _bookmarksFuture,
      builder: (_, snapshot) => GetBuilder<BookMarkManager>(
        builder: (_) {
          if (snapshot.connectionState != ConnectionState.done &&
              bookmarkManager.bookMarks.isEmpty) {
            return const TakoLoadingView(avoidBottomNavigation: true);
          }
          if (bookmarkManager.bookMarks.isEmpty) return _emptyState();

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 104),
            itemCount: bookmarkManager.bookMarks.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Your handpicked titles, ready whenever you are.',
                      style: TextStyle(color: tkMutedText, fontSize: 13)),
                );
              }
              final bookmark = bookmarkManager.bookMarks[index - 1];
              return _BookmarkCard(
                imageUrl: bookmark.imageUrl,
                name: bookmark.name,
                onTap: () => Get.toNamed(
                  Routes.videoListScreen,
                  arguments: {'anime': bookmark},
                ),
                onRemove: () async {
                  await bookmarkManager.removeFromBookMarks(bookmark);
                  Get.snackbar(
                    'Removed from Saved',
                    bookmark.name,
                    backgroundColor: tkDarkBlue,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(milliseconds: 1300),
                    margin: const EdgeInsets.all(16),
                  );
                },
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
            child: const Icon(Icons.bookmark_add_outlined,
                color: tkCoral, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Your Saved list is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Save an anime from its detail page to keep it here.',
              style: TextStyle(color: tkMutedText, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.imageUrl,
    required this.name,
    required this.onTap,
    required this.onRemove,
  });

  final String imageUrl;
  final String name;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 126,
          decoration: BoxDecoration(
            color: tkDarkBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
                child: SizedBox(
                  width: 92,
                  height: double.infinity,
                  child: NetworkImageWithCacheManager(imageUrl: imageUrl),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 16, 4, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SAVED TITLE',
                          style: TextStyle(
                              color: tkCoral,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.18,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const Text('View episodes',
                          style: TextStyle(color: tkMutedText, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove from Saved',
                icon: const Icon(Icons.bookmark_remove_outlined,
                    color: tkMutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
