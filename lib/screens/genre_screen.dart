import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../theme/tako_theme.dart';
import '../utils/constants.dart';
import '../widgets/searched_result_anime_card.dart';
import '../widgets/tako_animation.dart';
import '../widgets/tako_loading_indicator.dart';
import '../widgets/tako_scaffold.dart';

class GenreScreen extends StatefulWidget {
  const GenreScreen({super.key});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen>
    with SingleTickerProviderStateMixin {
  int _pageIndex = 1;
  final ValueNotifier<bool> _hasNoMoreResults = ValueNotifier(false);
  late AnimationController animationController;
  late final Genre _genre;
  late Future<AnimeResults> _pageFuture;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        duration: Duration(milliseconds: takoAnimationDuration), vsync: this);
    _genre = Get.arguments as Genre;
    _pageFuture = _loadPage();
  }

  @override
  void dispose() {
    animationController.dispose();
    _hasNoMoreResults.dispose();
    super.dispose();
  }

  Future<AnimeResults> _loadPage() async {
    final provider = Get.find<RequestService>();
    final results = await AnimeService(requestService: provider)
        .getAnimes(provider.requestAnimeGenre(_genre.link, _pageIndex));
    _hasNoMoreResults.value = results.animeList.isEmpty;
    return results;
  }

  void _reloadPage() {
    final pageFuture = _loadPage();
    setState(() {
      _pageFuture = pageFuture;
    });
    animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return TakoScaffoldWithBackButton(
      appBarTitle: _genre.name,
      body: Column(
        children: [
          Expanded(
              child: FutureBuilder<AnimeResults>(
                  future: _pageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'We could not load this page.',
                              style: TakoTheme.darkTextTheme.displaySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _reloadPage,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.done) {
                      final list = snapshot.data!.animeList;

                      if (list.isEmpty) {
                        return const Center(
                          child: Text(
                            'No more titles in this genre.',
                            style: TextStyle(color: tkMutedText),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          childAspectRatio: .56,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 40,
                          maxCrossAxisExtent: 220,
                        ),
                        itemCount: list.length,
                        itemBuilder: (BuildContext context, int index) {
                          return AnimatedBuilder(
                            animation: animationController,
                            child: SearchedResultAnimeCard(
                              anime: list[index],
                            ),
                            builder: (BuildContext context, Widget? child) {
                              return Transform(
                                transform: Matrix4.translationValues(
                                    0,
                                    100 *
                                        (1.0 -
                                            TakoCurveAnimation(
                                                    animationController,
                                                    index,
                                                    list.length)
                                                .value),
                                    0),
                                child: child,
                              );
                            },
                          );
                        },
                      );
                    } else {
                      return const Center(child: TakoLoadingIndicator());
                    }
                  })),
          Align(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: tkDarkBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      onTap: () {
                        if (_pageIndex != 1 && _pageIndex > 1) {
                          _pageIndex--;
                          _reloadPage();
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                            // color: tkLightGreen,
                            borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        )),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                            ),
                            Text('Prev'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Text(
                      _pageIndex.toString(),
                      style: TakoTheme.darkTextTheme.displaySmall!.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _hasNoMoreResults,
                    builder: (context, hasNoMoreResults, _) => Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        onTap: hasNoMoreResults
                            ? null
                            : () {
                                _pageIndex++;
                                _reloadPage();
                              },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                              // color: tkLightGreen,
                              borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          )),
                          child: Row(
                            children: const [
                              Text('Next'),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
