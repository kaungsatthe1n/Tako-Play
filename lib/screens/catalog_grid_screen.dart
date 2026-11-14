import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';
import '../widgets/searched_result_anime_card.dart';
import '../widgets/tako_loading_indicator.dart';

/// Displays a home catalog section as a full grid.
class CatalogGridScreen extends StatefulWidget {
  const CatalogGridScreen({super.key});

  @override
  State<CatalogGridScreen> createState() => _CatalogGridScreenState();
}

class _CatalogGridScreenState extends State<CatalogGridScreen> {
  late final String title;
  late final List<Anime> _items;
  late final Set<String> _excludedAnimeIds;
  late final ScrollController _scrollController;
  var _nextPage = 2;
  var _isLoadingMore = false;
  var _hasMore = true;
  var _loadError = false;

  bool get _canPaginate => title == 'Popular now' || title == 'Movies';

  @override
  void initState() {
    super.initState();
    final args = Map<String, dynamic>.from(Get.arguments as Map);
    title = args['title'] as String? ?? 'Anime';
    _items = (args['animeList'] as List? ?? const <dynamic>[])
        .whereType<Anime>()
        .toList();
    _excludedAnimeIds = (args['excludedAnimeIds'] as List? ?? const <dynamic>[])
        .whereType<String>()
        .toSet();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_canPaginate ||
        !_scrollController.hasClients ||
        _isLoadingMore ||
        !_hasMore ||
        _scrollController.position.extentAfter > 640) {
      return;
    }
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _loadError = false;
    });

    try {
      final requestService = Get.find<RequestService>();
      final animeService = AnimeService(requestService: requestService);
      final result = title == 'Popular now'
          ? await animeService
              .getAnimes(requestService.requestPopularResponse(_nextPage))
          : await animeService
              .getMovies(requestService.requestMoviesResponse(_nextPage));
      if (!mounted) return;

      final knownIds = _items.map((anime) => anime.id).toSet();
      final nextItems = result.animeList
          .where((anime) =>
              !_excludedAnimeIds.contains(anime.id) && knownIds.add(anime.id))
          .toList(growable: false);
      setState(() {
        _items.addAll(nextItems);
        _nextPage++;
        _hasMore = result.animeList.isNotEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  Material(
                    color: tkDarkBlue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: Get.back,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF29263F)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: TakoLoadingIndicator())
                  : CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              childAspectRatio: .57,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 18,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, index) => TweenAnimationBuilder<double>(
                                duration: Duration(
                                    milliseconds:
                                        220 + (index.clamp(0, 8) * 35)),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0, end: 1),
                                builder: (_, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 18 * (1 - value)),
                                    child: child,
                                  ),
                                ),
                                child: SearchedResultAnimeCard(
                                  anime: _items[index],
                                  heroTag: _cardHeroTag(title, _items[index]),
                                  enableHero: title != 'Movies',
                                ),
                              ),
                              childCount: _items.length,
                            ),
                          ),
                        ),
                        if (_canPaginate && (_isLoadingMore || _loadError))
                          SliverToBoxAdapter(child: _buildPaginationFooter()),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _cardHeroTag(String title, Anime anime) => title == 'Popular now'
      ? anime.id.toString()
      : 'catalog-New episodes-${anime.id}';

  Widget _buildPaginationFooter() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Center(
          child: _loadError
              ? TextButton.icon(
                  onPressed: _loadNextPage,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'Could not load more. Tap to retry',
                    style: GoogleFonts.dmSans(color: tkMutedText),
                  ),
                )
              : const TakoLoadingIndicator(size: 26),
        ),
      );
}
