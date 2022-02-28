import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../widgets/searched_result_anime_card.dart';

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
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
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

                      return AnimationLimiter(
                        child: GridView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 20.h),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: itemWidth / itemHeight,
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 40,
                          ),
                          itemCount: list!.length,
                          itemBuilder: (BuildContext context, int index) {
                            return AnimationConfiguration.staggeredGrid(
                              columnCount: 2,
                              position: index,
                              duration: const Duration(milliseconds: 800),
                              child: SlideAnimation(
                                verticalOffset: 100,
                                // horizontalOffset: 50,
                                child: FadeInAnimation(
                                  child: SearchedResultAnimeCard(
                                    anime: list[index],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: tkLightGreen,
                                      )));
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
