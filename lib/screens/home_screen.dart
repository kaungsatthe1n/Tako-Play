import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/update_manager.dart';
import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';
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
  late Future<AnimeResults> _recentlyAddedFuture;
  late Future<AnimeResults> _moviesFuture;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    animationController = AnimationController(
        duration: Duration(milliseconds: takoAnimationDuration), vsync: this);
    _loadCatalog();
    _checkForUpdate();
  }

  void _loadCatalog() {
    final requestService = Get.find<RequestService>();
    final animeService = AnimeService(requestService: requestService);
    _popularFuture = _keepCatalogSection(
      animeService.getAnimes(requestService.requestPopularResponse()),
    );
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
        UpdateAlertDialog(downloadLink: updateManager.downloadLink!),
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Text(
              'Find your next\nobsession.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 31,
                height: 1.04,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
              ),
            ),
          ),
          _buildPopularSection(),
          _buildRecentlyAddedSection(),
          _buildMoviesSection(),
        ],
      ),
    );
  }

  Widget _buildPopularSection() => _buildAnimeRail(
        future: _popularFuture,
        title: 'Popular now',
        subtitle: 'Handpicked for you',
        cardBuilder: (anime, _) => PopularAnimeCard(anime: anime),
      );

  Widget _buildRecentlyAddedSection() => _buildAnimeRail(
        future: _recentlyAddedFuture,
        title: 'New episodes',
        subtitle: 'Fresh releases to watch',
        cardBuilder: (anime, index) => AnimatedBuilder(
          animation: animationController,
          child: RecentlyAddedAnimeCard(anime: anime),
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
              _buildSectionTitle(title, subtitle),
              _buildHorizontalListView(
                animeList,
                (index) => cardBuilder(animeList[index], index),
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
              _buildSectionTitle('Movies', 'A complete story tonight'),
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 30, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: tkMutedText, fontSize: 12),
              ),
            ],
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tkDarkBlue,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.arrow_outward_rounded, size: 17),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalListView(
      List<Anime> animeList, Widget Function(int) itemBuilder) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: animeList.length,
        itemBuilder: (BuildContext context, int index) {
          return itemBuilder(index);
        },
      ),
    );
  }
}
