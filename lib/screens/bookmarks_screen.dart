import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../helpers/cache_manager.dart';
import '../models/bookmark.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class BookMarksScreen extends StatefulWidget {
  const BookMarksScreen({Key? key}) : super(key: key);

  @override
  State<BookMarksScreen> createState() => _BookMarksScreenState();
}

class _BookMarksScreenState extends State<BookMarksScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Provider.of<BookMarkProvider>(context, listen: false)
          .getAllBookMarkFromDatabase(),
      builder: (context, snapshot) => Consumer<BookMarkProvider>(
        builder: (context, provider, _) => ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: provider.bookMarks.length,
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
                      Get.toNamed(Routes.videoListScreen,
                          arguments: {'anime': provider.bookMarks[index]});
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
                              child: CachedNetworkImage(
                                key: UniqueKey(),
                                cacheManager: CustomCacheManager.instance,
                                imageUrl: provider.bookMarks[index].imageUrl,
                                fit: BoxFit.cover,
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
                              provider.bookMarks[index].name,
                              softWrap: true,
                              style: TakoTheme.darkTextTheme.headline3,
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              var bookmark = provider.bookMarks[index];
                              provider.removeFromBookMarks(bookmark);
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
