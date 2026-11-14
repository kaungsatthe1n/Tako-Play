import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';
import '../widgets/searched_result_anime_card.dart';
import '../widgets/tako_loading_indicator.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final hasValue = false.obs;
  final title = ''.obs;
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  late final AnimeService _animeService;
  var _requestRevision = 0;

  @override
  void initState() {
    super.initState();
    _animeService = AnimeService(requestService: Get.find<RequestService>());
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    if (_controller.text.trim().length < 3) {
      hasValue.value = false;
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 550), () {
      title.value = _controller.text.trim();
      hasValue.value = true;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tkDarkBlue,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search',
                      style: GoogleFonts.dmSans(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: TextField(
                autofocus: true,
                controller: _controller,
                textInputAction: TextInputAction.search,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onSubmitted: (value) {
                  final query = value.trim();
                  if (query.isEmpty) return;
                  _saveToRecentSearches(query);
                  title.value = query;
                  hasValue.value = true;
                },
                decoration: InputDecoration(
                  hintText: 'Search anime, movies, genres…',
                  prefixIcon: const Icon(Icons.search_rounded, color: tkCoral),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (_, value, __) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: _controller.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child:
                      hasValue.value ? _buildResults() : _buildRecentSearches(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return FutureBuilder<AnimeResults>(
      key: ValueKey('${title.value}:$_requestRevision'),
      future: _animeService.searchAnimes(title.value),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            'Search failed. Check your connection and try again.',
            Icons.wifi_off_rounded,
            onRetry: () => setState(() => _requestRevision++),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: TakoLoadingIndicator());
        }
        final list = snapshot.data?.animeList ?? <Anime>[];
        if (list.isEmpty) {
          return _emptyState('No matches found', Icons.search_off_rounded);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Text(
                '${list.length} results for “${title.value}”',
                style: const TextStyle(color: tkMutedText, fontSize: 13),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: .57,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                ),
                itemCount: list.length,
                itemBuilder: (_, index) => TweenAnimationBuilder<double>(
                  duration:
                      Duration(milliseconds: 220 + (index.clamp(0, 8) * 35)),
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
                    anime: list[index],
                    fallbackCategoryLabel: 'Series',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return FutureBuilder<List<String>>(
      future: _getRecentSearches(),
      builder: (_, snapshot) {
        final searches = snapshot.data ?? <String>[];
        if (searches.isEmpty) {
          return _emptyState('Start typing to find something great',
              Icons.auto_awesome_rounded);
        }
        return ListView(
          key: const ValueKey('recent-searches'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('RECENT SEARCHES',
                  style: TextStyle(
                      color: tkMutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            ...searches.map(
              (search) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: tkDarkBlue,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onTap: () {
                      _controller.text = search;
                      title.value = search;
                      hasValue.value = true;
                    },
                    leading:
                        const Icon(Icons.history_rounded, color: tkMutedText),
                    title: Text(search,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: IconButton(
                      onPressed: () async {
                        await _deleteSearch(search);
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, color: tkMutedText),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(
    String label,
    IconData icon, {
    VoidCallback? onRetry,
  }) {
    return Center(
      key: ValueKey(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration:
                const BoxDecoration(color: tkDarkBlue, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: tkCoral),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveToRecentSearches(String searchText) async {
    final preferences = await SharedPreferences.getInstance();
    final allSearches =
        preferences.getStringList('takoRecentSearches') ?? <String>[];
    await preferences.setStringList(
      'takoRecentSearches',
      [searchText, ...allSearches.where((item) => item != searchText)]
          .take(8)
          .toList(),
    );
  }

  Future<void> _deleteSearch(String searchText) async {
    final preferences = await SharedPreferences.getInstance();
    final searches =
        preferences.getStringList('takoRecentSearches') ?? <String>[];
    await preferences.setStringList(
      'takoRecentSearches',
      searches.where((item) => item != searchText).toList(),
    );
  }

  Future<List<String>> _getRecentSearches() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList('takoRecentSearches') ?? <String>[];
  }
}
