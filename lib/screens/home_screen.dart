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
  const HomeScreen({super.key});

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
    _popularFuture = _keepCatalogSection(
      animeService.getAnimes(requestService.requestPopularResponse()),
    );
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
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF302D55)),
                  ),
                  child: const Icon(Icons.search_rounded, size: 24),
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
                color: tkSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? tkGradientBlue : tkSurfaceBorder,
                  width: selected ? 1.4 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: GoogleFonts.dmSans(
                    color: selected ? Colors.white : const Color(0xFFD1D0E5),
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
                height: 290,
                child: PageView.builder(
                  itemCount: featured.length,
                  onPageChanged: (index) =>
                      setState(() => _featuredIndex = index),
                  itemBuilder: (context, index) =>
                      _buildFeaturedCard(featured[index], index + 1),
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

  Widget _buildFeaturedCard(Anime anime, int rank) => Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  anime.imageUrl.isEmpty
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF63B779), Color(0xFF12202B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: anime.imageUrl,
                          cacheManager: CustomCacheManager.instance,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          errorWidget: (_, __, ___) => const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF63B779), Color(0xFF12202B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x1A7867F7)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x2C4A3B8B),
                          Color(0x0C101220),
                          Color(0x55090A12),
                        ],
                        stops: [0, .4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xE8FF8B7B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55200821),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded,
                              color: Color(0xFF541D20), size: 15),
                          const SizedBox(width: 5),
                          Text('TRENDING',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF541D20),
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                                fontSize: 10,
                              )),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xB8171725),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        '$rank / 5',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
                      decoration: BoxDecoration(
                        color: const Color(0x8A0C0D17),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: .16)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x48000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(anime.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 24,
                                height: 1.05,
                                letterSpacing: -.7,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 7),
                          Text(
                            anime.genres
                                    .take(2)
                                    .map((genre) => genre.name)
                                    .join(' · ')
                                    .isEmpty
                                ? 'Anime · Discover something new'
                                : anime.genres
                                    .take(2)
                                    .map((genre) => genre.name)
                                    .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFFD3D1E5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final buttonWidth =
                                  (constraints.maxWidth - 57).clamp(0.0, 230.0);
                              return Row(
                                children: [
                                  SizedBox(
                                    width: buttonWidth,
                                    height: 44,
                                    child: FilledButton.icon(
                                      onPressed: () => Get.toNamed(
                                        Routes.videoListScreen,
                                        arguments: {'anime': anime},
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF3F2FA),
                                        foregroundColor: tkDarkerBlue,
                                        minimumSize: const Size(0, 44),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        shape: const StadiumBorder(),
                                      ),
                                      icon: const Icon(Icons.play_arrow_rounded,
                                          size: 21),
                                      label: Text('Watch now',
                                          maxLines: 1,
                                          softWrap: false,
                                          style: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  _buildFeaturedBookmark(anime),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          child: Hero(
            tag: _catalogCardHeroTag(anime),
            child: Material(
              color: Colors.transparent,
              child: RecentlyAddedAnimeCard(anime: anime),
            ),
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
                height: 280,
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

  String _catalogCardHeroTag(Anime anime) => 'catalog-New episodes-${anime.id}';

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
          Material(
            color: tkDarkBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSeeAll,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF29263F)),
                ),
                child: const Icon(Icons.arrow_outward_rounded, size: 17),
              ),
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
