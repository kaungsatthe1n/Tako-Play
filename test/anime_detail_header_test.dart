import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/utils/routes.dart';
import 'package:tako_play/widgets/anime_detail_header.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  final anime = Anime(
    id: 'header',
    status: 'ONGOING',
    releasedDate: '2026',
    genres: [Genre(name: 'Action', link: '/genre/action')],
  );

  testWidgets('renders metadata in wide and compact layouts and opens genre',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: AnimeDetailHeader(
              anime: anime,
              name: 'Header show',
              imageUrl: '',
            ),
          ),
        ),
        getPages: [
          GetPage(
            name: Routes.genreScreen,
            page: () => const Scaffold(body: Text('Genre destination')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ONGOING'), findsOneWidget);
    expect(find.text('Released 2026'), findsOneWidget);

    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(find.text('Genre destination'), findsOneWidget);
  });

  testWidgets('uses compact header layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: AnimeDetailHeader(
              anime: Anime(),
              name: 'Compact show',
              imageUrl: '',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ANIME'), findsOneWidget);
    expect(find.text('Now streaming'), findsOneWidget);
  });
}
