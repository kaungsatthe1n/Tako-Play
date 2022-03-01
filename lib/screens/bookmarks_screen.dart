import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/bookmark_manager.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/cache_image_with_cachemanager.dart';

class BookMarksScreen extends StatelessWidget {
  final bookmarkMaanger = Get.find<BookMarkManager>();
  BookMarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: bookmarkMaanger.loadBookMarksFromDatabase(),
      builder: (context, snapshot) => GetBuilder<BookMarkManager>(
        builder: (_) => ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: bookmarkMaanger.bookMarks.length,
            itemBuilder: (context, index) {
              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    tkGradientBlack,
                    tkGradientBlue,
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      spreadRadius: 0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                width: double.infinity,
                height: 150,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Get.toNamed(Routes.videoListScreen, arguments: {
                        'anime': bookmarkMaanger.bookMarks[index]
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AspectRatio(
                            aspectRatio: 0.6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: NetworkImageWithCacheManager(
                                imageUrl:
                                    bookmarkMaanger.bookMarks[index].imageUrl,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            alignment: Alignment.topLeft,
                            child: Text(
                              bookmarkMaanger.bookMarks[index].name,
                              softWrap: true,
                              style: TakoTheme.darkTextTheme.headline3,
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              var bookmark = bookmarkMaanger.bookMarks[index];
                              bookmarkMaanger.removeFromBookMarks(bookmark);
                              Get.snackbar(bookmark.name,
                                  'Removed from bookmark successfully!',
                                  backgroundColor: Colors.black38,
                                  duration: const Duration(milliseconds: 1300),
                                  snackPosition: SnackPosition.BOTTOM);
                            },
                            icon: const Icon(
                              Icons.bookmark_remove_rounded,
                              color: Colors.redAccent,
                              semanticLabel: 'Remove',
                            ))
                      ],
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
