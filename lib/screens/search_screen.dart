import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tako_play/services/request_service.dart';
import '../helpers/cache_manager.dart';
import '../utils/constants.dart';
import '../theme/tako_theme.dart';
import '../utils/routes.dart';
import '../models/anime.dart';
import '../services/anime_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var hasValue = false.obs;
  var title = ''.obs;
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text.length >= 4) {
        title.value = _controller.text;
        hasValue.value = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemHeight = ((screenHeight - kToolbarHeight - 24) / 2).h;
    final itemWidth = (screenWidth / 2).w;
    final provider = Provider.of<RequestService>(context);

    return Scaffold(
        appBar: AppBar(
          title: TextField(
            key: _formKey,
            controller: _controller,
            decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _controller.clear();
                    hasValue.value = false;
                  },
                ),
                hintText: 'Search...',
                border: InputBorder.none),
            onSubmitted: (val) {
              _saveToRecentSearches(val);
              hasValue.value = true;
              title.value = val;
            },
          ),
        ),
        body: Obx(
          () => hasValue.value
              ? FutureBuilder<AnimeResults>(
                  future: AnimeService()
                      .getAnimes(provider.requestSearchResponse(title.value)),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'No Results Found !',
                          style: TakoTheme.darkTextTheme.headline3,
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.done) {
                      final list = snapshot.data!.animeList;

                      return GridView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 20.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: itemWidth / itemHeight,
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 40,
                        ),
                        itemCount: list!.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              Get.toNamed(
                                Routes.videoListScreen,
                                arguments: {'anime': list[index]},
                              );
                            },
                            child: Hero(
                              tag: list[index].id.toString(),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 0.7,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: CachedNetworkImage(
                                          key: UniqueKey(),
                                          cacheManager:
                                              CustomCacheManager.instance,
                                          fit: BoxFit.cover,
                                          imageUrl:
                                              list[index].imageUrl.toString(),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 20.h),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          list[index].name.toString(),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style:
                                              TakoTheme.darkTextTheme.bodyText1,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF133F6E),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          list[index].releasedDate.toString(),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: TakoTheme
                                              .darkTextTheme.bodyText1!
                                              .copyWith(color: tkLightGreen),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: loadingIndicator,
                      );
                    }
                  })
              : FutureBuilder<List<String>>(
                  future: _getRecentSearches(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final searches = snapshot.data;
                      if (searches!.isNotEmpty) {
                        return ListView.builder(
                            itemCount: searches.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                  key: Key(index.toString()),
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setState(() {
                                      title.value = searches[index];
                                      _controller.text = title.value;
                                      hasValue.value = true;
                                    });
                                  },
                                  title: Text(searches[index]),
                                  trailing: IconButton(
                                      onPressed: () {
                                        _deleteSearch(searches[index]);
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.delete_forever)));
                            });
                      }
                    }
                    return const SizedBox();
                  }),
        ));
  }

  Future<void> _saveToRecentSearches(searchText) async {
    if (searchText != null) {
      final pref = await SharedPreferences.getInstance();
      Set<String> allSearches =
          pref.getStringList('takoRecentSearches')?.toSet() ?? {};

      allSearches = {searchText, ...allSearches};
      pref.setStringList('takoRecentSearches', allSearches.toList());
    }
  }

  Future<void> _deleteSearch(searchText) async {
    final pref = await SharedPreferences.getInstance();
    final newList = pref
        .getStringList('takoRecentSearches')!
        .where((result) => result != searchText)
        .toList();
    pref.setStringList('takoRecentSearches', newList);
  }

  Future<List<String>> _getRecentSearches() async {
    final pref = await SharedPreferences.getInstance();
    final allSearches = pref.getStringList('takoRecentSearches');
    if (allSearches != null) {
      return allSearches.toList();
    }
    return [];
  }
}
