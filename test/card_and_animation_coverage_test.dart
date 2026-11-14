import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/movie_card.dart';
import 'package:tako_play/widgets/popular_anime_card.dart';
import 'package:tako_play/widgets/tako_animation.dart';

const _anime = Anime(
  id: 'coverage-show',
  name: 'Coverage title',
  imageUrl: '',
  animeUrl: 'https://example.com/anime/coverage-show',
);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  Future<void> pumpCards(WidgetTester tester, Widget card) {
    return tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: card),
        getPages: [
          GetPage(
            name: Routes.videoListScreen,
            page: () => const Scaffold(body: Text('Episode details')),
          ),
        ],
      ),
    );
  }

  testWidgets('popular card renders its empty-poster state and opens details',
      (tester) async {
    await pumpCards(tester, const PopularAnimeCard(anime: _anime));

    expect(find.text('POPULAR'), findsOneWidget);
    expect(find.text('Coverage title'), findsOneWidget);

    await tester.tap(find.byType(PopularAnimeCard));
    await tester.pumpAndSettle();
    expect(find.text('Episode details'), findsOneWidget);
  });

  testWidgets('movie card renders its empty-poster state and opens details',
      (tester) async {
    await pumpCards(tester, const MovieCard(anime: _anime));

    expect(find.text('MOVIE'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);

    await tester.tap(find.byType(MovieCard));
    await tester.pumpAndSettle();
    expect(find.text('Episode details'), findsOneWidget);
  });

  testWidgets('TakoCurveAnimation starts at zero and reaches one',
      (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 100),
    );
    addTearDown(controller.dispose);

    final animation = TakoCurveAnimation(controller, 0, 2);
    expect(animation.value, 0);

    controller.forward();
    await tester.pumpAndSettle();
    expect(animation.value, 1);
  });
}
