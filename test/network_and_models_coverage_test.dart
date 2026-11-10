import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/helpers/network_manager.dart';
import 'package:tako_play/models/anime.dart';

void main() {
  test('network manager reports reachability only with an interface and source',
      () async {
    final online = NetworkManager(
      autoStart: false,
      sourceUri: Uri.parse('https://example.com'),
      client: MockClient((request) async {
        expect(request.method, 'HEAD');
        return http.Response('', 204);
      }),
    );
    await online.updateConnectionState([ConnectivityResult.wifi]);
    expect(online.isOnline, isTrue);

    await online.updateConnectionState([ConnectivityResult.none]);
    expect(online.isOnline, isFalse);

    final rejected = NetworkManager(
      autoStart: false,
      client: MockClient((_) async => http.Response('', 503)),
    );
    await rejected.updateConnectionState([ConnectivityResult.mobile]);
    expect(rejected.isOnline, isFalse);

    final unavailable = NetworkManager(
      autoStart: false,
      client: MockClient((_) async => throw Exception('offline')),
    );
    await unavailable.updateConnectionState([ConnectivityResult.ethernet]);
    expect(unavailable.isOnline, isFalse);
  });

  test('anime value objects expose provided data and the full genre list', () {
    const result = AnimeResults(
      animeList: [Anime(id: 'show', name: 'Show', currentEp: 'Episode 3')],
    );

    expect(result.animeList.single.name, 'Show');
    expect(result.animeList.single.currentEp, 'Episode 3');
    expect(genreList, hasLength(18));
    expect(genreList.first.name, 'Action');
    expect(genreList.last.name, 'Thriller');

    final genre = Genre(name: 'Test', link: 'https://example.com/genre');
    final episode = Episode(number: '7', link: 'https://example.com/episode');
    expect(genre.link, contains('genre'));
    expect(episode.number, '7');
  });
}
