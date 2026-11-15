import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/bookmark_manager.dart';
import '../helpers/cache_manager.dart';
import '../helpers/update_manager.dart';
import '../models/anime.dart';
import '../models/bookmark.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/movie_card.dart';
import '../widgets/popular_anime_card.dart';
import '../widgets/recently_added_anime_card.dart';
import '../widgets/tako_animation.dart';
import '../widgets/tako_loading_indicator.dart';
import '../widgets/update_alert_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.featuredResults});

  /// Optional catalog source for deterministic rendering tests.
  final Future<AnimeResults>? featuredResults;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController animationController;
  late Future<AnimeResults> _popularFuture;
  late Future<AnimeResults> _popularWithoutFeaturedFuture;
  late Future<AnimeResults> _recentlyAddedFuture;
  late Future<AnimeResults> _moviesFuture;
  int _featuredIndex = 0;
  String _selectedGenre = '';
  Set<String> _featuredAnimeIds = <String>{};
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    animationController = AnimationController(
        duration: Duration(milliseconds: takoAnimationDuration), vsync: this);
    unawaited(Get.find<BookMarkManager>()
        .loadBookMarksFromDatabase()
        .catchError((_) {}));
    _loadCatalog();
    _checkForUpdate();
  }

  void _loadCatalog() {
    final requestService = Get.find<RequestService>();
    final animeService = AnimeService(requestService: requestService);
    _popularFuture = _keepCatalogSection(widget.featuredResults ??
        animeService.getAnimes(requestService.requestPopularResponse()));
    _popularWithoutFeaturedFuture = _popularFuture.then((results) {
      _featuredAnimeIds =
          results.animeList.take(5).map((anime) => anime.id).toSet();
      return AnimeResults(
        animeList: results.animeList
            .where((anime) => !_featuredAnimeIds.contains(anime.id))
            .toList(growable: false),
      );
    });
    _recentlyAddedFuture = _keepCatalogSection(
      animeService.getRecentlyAddedAnimes(),
    ).then((result) {
      if (mounted && result.animeList.isNotEmpty) {
        animationController.forward(from: 0);
      }
      return result;
    });
    _moviesFuture = _keepCatalogSection(
      animeService.getMovies(requestService.requestMoviesResponse()),
    );
  }

  Future<AnimeResults> _keepCatalogSection(
    Future<AnimeResults> request,
  ) async {
    try {
      return await request;
    } catch (_) {
      return const AnimeResults(animeList: <Anime>[]);
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _checkForUpdate() async {
    final updateManager = Get.find<UpdateManager>();
    await updateManager.checkForUpdate();
    if (mounted && updateManager.isUpdateAvailable) {
      await Get.dialog(
        UpdateAlertDialog(
          downloadLink: updateManager.downloadLink!,
          isDirectApkDownload: updateManager.usesApkDownload,
        ),
      );
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHomeHeader(),
            _buildGenreChips(),
            const SizedBox(height: 16),
            _buildFeatured(),
            _buildPopularSection(),
            _buildRecentlyAddedSection(),
            _buildMoviesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Text('Discover',
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    height: 1.1,
                    letterSpacing: -.9,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            Material(
              color: tkDarkBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Get.toNamed(Routes.searchScreen),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.search_rounded, size: 24),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildGenreChips() {
    final genres = genreList.map((genre) => genre.name).toList(growable: false);
    return SizedBox(
      height: 50,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final label = genres[index];
          final selected = _selectedGenre == label;
          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              setState(() => _selectedGenre = label);
              if (label != 'All') {
                final genre =
                    genreList.firstWhere((item) => item.name == label);
                Get.toNamed(Routes.genreScreen, arguments: genre);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF8E80F9) : tkDarkBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: GoogleFonts.dmSans(
                    color: selected ? tkDarkerBlue : const Color(0xFFD1D0E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatured() => FutureBuilder<AnimeResults>(
        future: _popularFuture,
        builder: (context, snapshot) {
          final items = snapshot.data?.animeList ?? const <Anime>[];
          if (items.isEmpty) return const SizedBox(height: 12);
          final featured = items.take(5).toList(growable: false);
          final selected = _featuredIndex.clamp(0, featured.length - 1);
          return Column(
            children: [
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: featured.length,
                  onPageChanged: (index) =>
                      setState(() => _featuredIndex = index),
                  itemBuilder: (context, index) =>
                      _buildFeaturedCard(featured[index]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(featured.length, (index) {
                  final active = index == selected;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? tkGradientBlue : const Color(0xFF39385D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      );

  Widget _buildFeaturedCard(Anime anime) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (anime.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: anime.imageUrl,
                  cacheManager: CustomCacheManager.instance,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: tkDarkBlue),
                )
              else
                const ColoredBox(color: tkDarkBlue),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x360A0915),
                      Color(0x600A0915),
                      Color(0xF50A0915),
                    ],
                    stops: [0, .38, 1],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xC8261421),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: Color(0xFFFFA89C), size: 16),
                      const SizedBox(width: 6),
                      Text('TRENDING',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFFFFA89C),
                            fontWeight: FontWeight.w900,
                            letterSpacing: .6,
                            fontSize: 11,
                          )),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anime.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.05,
                          letterSpacing: -.6,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      anime.genres.isNotEmpty
                          ? anime.genres
                              .take(2)
                              .map((genre) => genre.name)
                              .join(' · ')
                          : (anime.currentEp.isNotEmpty
                              ? anime.currentEp
                              : 'Anime'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFD3D1E5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: () => Get.toNamed(
                                Routes.videoListScreen,
                                arguments: {'anime': anime},
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F2FA),
                                foregroundColor: tkDarkerBlue,
                                shape: const StadiumBorder(),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 21),
                              label: Text('Watch now',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildFeaturedBookmark(anime),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFeaturedBookmark(Anime anime) => GetBuilder<BookMarkManager>(
        builder: (manager) {
          final saved = manager.ids.contains(anime.id);
          return Material(
            color: Colors.white.withValues(alpha: .18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                final bookmark = BookMark(
                  id: anime.id,
                  name: anime.name,
                  imageUrl: anime.imageUrl,
                  animeUrl: anime.animeUrl,
                );
                if (saved) {
                  await manager.removeFromBookMarks(bookmark);
                } else {
                  await manager.addToBookMarks(bookmark);
                }
              },
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border_rounded),
              ),
            ),
          );
        },
      );

  Widget _buildPopularSection() => _buildAnimeRail(
        future: _popularWithoutFeaturedFuture,
        title: 'Popular now',
        subtitle: '',
        cardBuilder: (anime, _) => PopularAnimeCard(anime: anime),
      );

  Widget _buildRecentlyAddedSection() => _buildAnimeRail(
        future: _recentlyAddedFuture,
        title: 'New episodes',
        subtitle: 'Fresh releases to watch',
        cardBuilder: (anime, index) => AnimatedBuilder(
          animation: animationController,
          child: Material(
            color: Colors.transparent,
            child: RecentlyAddedAnimeCard(anime: anime),
          ),
          builder: (context, child) => Transform(
            transform: Matrix4.translationValues(
              -200 *
                  (1.0 -
                      TakoCurveAnimation(
                        animationController,
                        index,
                        20,
                      ).value),
              0,
              0,
            ),
            child: child,
          ),
        ),
      );

  Widget _buildAnimeRail({
    required Future<AnimeResults> future,
    required String title,
    required String subtitle,
    required Widget Function(Anime anime, int index) cardBuilder,
  }) =>
      FutureBuilder<AnimeResults>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSectionLoading(title, subtitle);
          }
          final animeList = snapshot.data?.animeList ?? const <Anime>[];
          if (animeList.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              _buildSectionTitle(
                title,
                subtitle,
                onSeeAll: () => _openCatalogGrid(title, animeList),
              ),
              _buildHorizontalListView(
                animeList,
                (index) => cardBuilder(animeList[index], index),
                height: title == 'Popular now' ? 235 : 280,
              ),
            ],
          );
        },
      );

  Widget _buildMoviesSection() => FutureBuilder<AnimeResults>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildSectionLoading('Movies', 'A complete story tonight');
          }
          final movies = snapshot.data?.animeList ?? const <Anime>[];
          if (movies.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              _buildSectionTitle(
                'Movies',
                'A complete story tonight',
                onSeeAll: () => _openCatalogGrid('Movies', movies),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: movies
                      .map((anime) => MovieCard(anime: anime))
                      .toList(growable: false),
                ),
              ),
            ],
          );
        },
      );

  Widget _buildSectionLoading(String title, String subtitle) => Column(
        children: [
          _buildSectionTitle(title, subtitle),
          const SizedBox(
            height: 120,
            child: Center(child: TakoLoadingIndicator(size: 32)),
          ),
        ],
      );

  Future<void> _openCatalogGrid(String title, List<Anime> items) async {
    await Get.toNamed(Routes.catalogGridScreen, arguments: {
      'title': title,
      'animeList': List<Anime>.of(items),
      if (title == 'Popular now')
        'excludedAnimeIds': _featuredAnimeIds.toList(growable: false),
    });
  }

  Widget _buildSectionTitle(
    String title,
    String subtitle, {
    VoidCallback? onSeeAll,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (subtitle.isEmpty)
            Text(title,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                ))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.45,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: tkMutedText, fontSize: 12)),
              ],
            ),
          if (onSeeAll != null)
            TextButton.icon(
              onPressed: onSeeAll,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: const Text('See all'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA69AFF),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalListView(
      List<Anime> animeList, Widget Function(int) itemBuilder,
      {required double height}) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: animeList.length,
        itemBuilder: (BuildContext context, int index) {
          return itemBuilder(index);
        },
      ),
    );
  }
}
