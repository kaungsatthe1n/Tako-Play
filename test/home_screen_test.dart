import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/helpers/update_manager.dart';
import 'package:tako_play/screens/home_screen.dart';
import 'package:tako_play/services/request_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() async => Get.reset());

  testWidgets('renders completed popular, new episode, and movie rails',
      (tester) async {
    final requestService = RequestService(
      client: MockClient((request) async {
        if (request.url.host.contains('github')) {
          return http.Response('{"tag_name":"v1.8.0","assets":[]}', 200);
        }
        final isMovie = request.url.path.contains('/movies');
        return http.Response(
          '''
            <main><section><ul class="grid"><li>
              <a href="/watch/${isMovie ? 'movie' : 'show'}-1/"><img src="/poster.webp"></a>
              <span>${isMovie ? 'Movie' : 'Ep 4'}</span>
              <p><a href="/watch/${isMovie ? 'movie' : 'show'}-1/">${isMovie ? 'Movie night' : 'Featured show'}</a></p>
            </li></ul></section></main>
          ''',
          200,
        );
      }),
    );
    Get.put(requestService);
    Get.put(UpdateManager(requestService: requestService));

    await tester.pumpWidget(const GetMaterialApp(home: HomeScreen()));
    expect(find.text('Popular now'), findsOneWidget);
    expect(find.text('New episodes'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Featured show'), findsNWidgets(2));
    expect(find.text('Movie night'), findsOneWidget);
  });
}
