import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/screens/genre_screen.dart';
import 'package:tako_play/services/request_service.dart';
import 'package:tako_play/widgets/searched_result_anime_card.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('places the first genre row directly below the app bar',
      (tester) async {
    Get.put(RequestService(
      client: MockClient((_) async => http.Response(_genreMarkup, 200)),
    ));
    await tester.pumpWidget(const GetMaterialApp(home: _OpenGenre()));

    await tester.tap(find.text('Open genre'));
    await tester.pump();
    await tester.pumpAndSettle();

    final firstCard = find.byType(SearchedResultAnimeCard).first;
    expect(firstCard, findsOneWidget);
    expect(tester.getTopLeft(firstCard).dy, lessThan(130));
  });
}

class _OpenGenre extends StatelessWidget {
  const _OpenGenre();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const GenreScreen(),
              arguments: Genre(
                name: 'Adventure',
                link: 'https://gogoanimes.org/genre/adventure/',
              ),
            ),
            child: const Text('Open genre'),
          ),
        ),
      );
}

const _genreMarkup = '''
  <main>
    <section>
      <ul class="grid">
        <li class="group">
          <a href="/watch/test-title-1/"><img src="/poster.jpg"></a>
          <p><a href="/watch/test-title-1/">Test title</a></p>
          <span>Ep 1</span>
        </li>
      </ul>
    </section>
  </main>
''';
