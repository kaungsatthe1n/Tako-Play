import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/widgets/tako_play_web_view.dart';

void main() {
  test('allows secure player redirects and blocks non-web schemes', () {
    expect(isAllowedPlayerNavigation('https://player.example.com/embed/1'),
        isTrue);
    expect(
        isAllowedPlayerNavigation('https://edge.example.net/stream/1'), isTrue);
    expect(isAllowedPlayerNavigation('http://player.example.com/embed/1'),
        isFalse);
    expect(isAllowedPlayerNavigation('intent://open-player'), isFalse);
  });

  test('allows the resolved player host but not unrelated destinations', () {
    const trustedHosts = {'player.example.com'};

    expect(isTrustedPlayerHost('player.example.com', trustedHosts), isTrue);
    expect(isTrustedPlayerHost('cdn.player.example.com', trustedHosts), isTrue);
    expect(isTrustedPlayerHost('ad.example.net', trustedHosts), isFalse);
  });

  test('only retries another advertised player after its document returns 410',
      () {
    final activePlayer = Uri.parse('https://player.example.com/embed/1');

    expect(
      shouldTryNextPlayerEmbed(
        statusCode: 410,
        errorUri: activePlayer,
        activePageUri: activePlayer,
        remainingPlayerUris: [
          Uri(scheme: 'https', host: 'backup.example.com', path: '/embed/1'),
        ],
      ),
      isTrue,
    );
    expect(
      shouldTryNextPlayerEmbed(
        statusCode: 410,
        errorUri: Uri.parse('https://cdn.example.com/segment.ts'),
        activePageUri: activePlayer,
        remainingPlayerUris: [
          Uri(scheme: 'https', host: 'backup.example.com', path: '/embed/1'),
        ],
      ),
      isFalse,
    );
    expect(
      shouldTryNextPlayerEmbed(
        statusCode: 404,
        errorUri: activePlayer,
        activePageUri: activePlayer,
        remainingPlayerUris: [
          Uri(scheme: 'https', host: 'backup.example.com', path: '/embed/1'),
        ],
      ),
      isFalse,
    );
  });

  test('retries when a source-listed nested player returns 410', () {
    final wrapper = Uri.parse('https://wrapper.example.com/newplayer');
    final nestedPlayer = Uri.parse('https://player.example.com/embed/1');

    expect(
      shouldTryNextPlayerEmbed(
        statusCode: 410,
        errorUri: Uri.parse(
          'https://player.example.com/embed/1?autostart=true',
        ),
        activePageUri: wrapper,
        remainingPlayerUris: [nestedPlayer],
      ),
      isTrue,
    );
    expect(
      shouldTryNextPlayerEmbed(
        statusCode: 410,
        errorUri: Uri.parse('https://player.example.com/asset.png'),
        activePageUri: wrapper,
        remainingPlayerUris: [nestedPlayer],
      ),
      isFalse,
    );
  });
}
