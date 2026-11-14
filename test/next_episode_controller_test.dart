import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/helpers/next_episode_controller.dart';
import 'package:tako_play/models/anime.dart';
import 'package:tako_play/models/playback_context.dart';
import 'package:tako_play/services/ending_timing_service.dart';
import 'package:tako_play/services/playback_service.dart';
import 'package:tako_play/widgets/next_episode_overlay.dart';

PlaybackContext contextAt(int index) => PlaybackContext(
      id: 'show',
      name: 'Test show',
      imageUrl: '',
      animeUrl: '/show',
      episodes: ['1', '2', '2.5', '4']
          .map((n) => Episode(number: n, link: '/ep/$n'))
          .toList(),
      index: index,
    );

PlaybackContext titledContext(String title, String episode) => PlaybackContext(
      id: title,
      name: title,
      imageUrl: '',
      animeUrl: '/$title',
      episodes: [
        Episode(number: episode, link: '/$title/$episode'),
        Episode(number: '${episode}a', link: '/$title/${episode}a'),
      ],
      index: 0,
    );
const source = PlaybackSource(
    url: 'https://cdn.example/master.m3u8',
    headers: {},
    subtitles: [
      PlaybackSubtitle(
          url: 'https://cdn.example/en.vtt',
          name: 'English',
          headers: {'Referer': 'https://player.example/'})
    ]);
const duration = Duration(seconds: 1440);
Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('prefetches once before ED and switches only on user action', () async {
    var loads = 0;
    final played = <String>[];
    final controller = NextEpisodeController(
        context: contextAt(0),
        findEnding: (_, __) async => const Duration(seconds: 1320),
        loadSource: (next) async {
          loads++;
          return source;
        },
        playSource: (next, prepared) async {
          expect(identical(prepared, source), isTrue);
          expect(prepared.subtitles.single.headers['Referer'], isNotEmpty);
          played.add(next.episode.number);
        });
    addTearDown(controller.dispose);
    controller.updateProgress(const Duration(seconds: 1), duration);
    await flush();
    controller.updateProgress(const Duration(seconds: 1259), duration);
    expect(loads, 0);
    controller.updateProgress(const Duration(seconds: 1260), duration);
    controller.updateProgress(const Duration(seconds: 1261), duration);
    await flush();
    expect(loads, 1);
    expect(controller.isReady, isTrue);
    expect(controller.isVisible, isFalse);
    controller.updateProgress(const Duration(seconds: 1320), duration);
    expect(controller.isVisible, isTrue);
    expect(played, isEmpty);
    await controller.playNext();
    expect(played, ['2']);
    expect(loads, 1);
    expect(controller.next!.episode.number, '2.5');
    expect(controller.context!.toRecent().animeUrl, '/show');
    expect(controller.isVisible, isFalse);
  });

  test('missing/invalid metadata falls back, seeking hides, dismissal persists',
      () async {
    final controller = NextEpisodeController(
        context: contextAt(0),
        findEnding: (_, __) async => const Duration(seconds: 9000),
        loadSource: (_) async => source,
        playSource: (_, __) async {});
    addTearDown(controller.dispose);
    controller.updateProgress(const Duration(seconds: 1409), duration);
    await flush();
    expect(controller.hasEndingTiming, isFalse);
    expect(controller.isVisible, isFalse);
    controller.updateProgress(const Duration(seconds: 1410), duration);
    expect(controller.isVisible, isTrue);
    controller.updateProgress(const Duration(seconds: 500), duration);
    expect(controller.isVisible, isFalse);
    controller.updateProgress(duration, duration);
    controller.dismiss();
    controller.updateProgress(duration, duration);
    expect(controller.isVisible, isFalse);
  });

  test('shows the opening overlay when progress enters its interval', () {
    final controller = NextEpisodeController(
      context: contextAt(0),
      opening: const SkipInterval(
        start: Duration(seconds: 60),
        end: Duration(seconds: 100),
      ),
      findEnding: (_, __) async => null,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);
    controller.updateProgress(const Duration(seconds: 59), duration);
    expect(controller.isOpeningVisible, isFalse);
    controller.updateProgress(const Duration(seconds: 60), duration);
    expect(controller.isOpeningVisible, isTrue);
  });

  test('opening timing is evaluated before recent episode context restores',
      () {
    final controller = NextEpisodeController(
      context: null,
      opening: const SkipInterval(
        start: Duration(seconds: 60),
        end: Duration(seconds: 100),
      ),
      findEnding: (_, __) async => null,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);

    controller.updateProgress(const Duration(seconds: 80), duration);

    expect(controller.isOpeningVisible, isTrue);
    expect(controller.isVisible, isFalse);
  });

  test('late context restoration reveals a next prompt at the current marker',
      () {
    final controller = NextEpisodeController(
      context: null,
      endingStart: const Duration(seconds: 1300),
      findEnding: (_, __) async => null,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);

    controller.updateProgress(const Duration(seconds: 1300), duration);
    expect(controller.isVisible, isFalse);
    controller.attachContext(titledContext('Frieren', '1'));

    expect(controller.isVisible, isTrue);
  });

  test('fetched ED markers show the overlay for multiple titles and episodes',
      () {
    final fixtures = [
      ('Bleach', '1', 1300, 1420),
      ('Frieren: Beyond Journey’s End', '1', 1450, 1560),
      ('Jujutsu Kaisen', '4', 1400, 1500),
    ];
    for (final (title, episode, endingAt, length) in fixtures) {
      final marker = Duration(seconds: endingAt);
      final controller = NextEpisodeController(
        context: titledContext(title, episode),
        endingStart: marker,
        findEnding: (_, __) async => null,
        loadSource: (_) async => source,
        playSource: (_, __) async {},
      );

      controller.updateProgress(
          marker - const Duration(seconds: 1), Duration(seconds: length));
      expect(controller.isVisible, isFalse, reason: '$title episode $episode');
      controller.updateProgress(marker, Duration(seconds: length));
      expect(controller.isVisible, isTrue, reason: '$title episode $episode');
      controller.dispose();
    }
  });

  test('ending timing fetched before a seek is still applied', () async {
    final ending = Completer<Duration?>();
    final controller = NextEpisodeController(
      context: contextAt(0),
      findEnding: (_, __) => ending.future,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);
    controller.updateProgress(const Duration(seconds: 100), duration);
    controller.onSeek();
    controller.updateProgress(const Duration(seconds: 1300), duration);
    ending.complete(const Duration(seconds: 1320));
    await flush();
    expect(controller.promptAt, const Duration(seconds: 1320));
    controller.updateProgress(const Duration(seconds: 1320), duration);
    expect(controller.isVisible, isTrue);
  });

  test('keeps extractor ending timing if AniSkip has no matching record',
      () async {
    final controller = NextEpisodeController(
      context: contextAt(0),
      endingStart: const Duration(seconds: 1300),
      findEnding: (_, __) async => null,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);
    controller.updateProgress(
        const Duration(seconds: 1100), const Duration(seconds: 1200));
    await flush();
    controller.updateProgress(const Duration(seconds: 1299), duration);
    expect(controller.promptAt, const Duration(seconds: 1300));
    controller.updateProgress(const Duration(seconds: 1300), duration);
    expect(controller.isVisible, isTrue);
  });

  test('final episode and unknown duration never fetch or show a prompt',
      () async {
    var requests = 0;
    final controller = NextEpisodeController(
        context: contextAt(3),
        findEnding: (_, __) async {
          requests++;
          return null;
        },
        loadSource: (_) async {
          requests++;
          return source;
        },
        playSource: (_, __) async {
          requests++;
        });
    addTearDown(controller.dispose);
    controller.updateProgress(duration, Duration.zero);
    controller.updateProgress(duration, duration);
    await controller.playNext();
    expect(requests, 0);
    expect(controller.isVisible, isFalse);
  });

  test('a failed prefetch retries on tap without retrying every progress tick',
      () async {
    var loads = 0;
    var plays = 0;
    final controller = NextEpisodeController(
        context: contextAt(0),
        findEnding: (_, __) async => null,
        loadSource: (_) async {
          if (++loads == 1) throw Exception('offline');
          return source;
        },
        playSource: (_, __) async {
          plays++;
        });
    addTearDown(controller.dispose);
    controller.updateProgress(const Duration(seconds: 1420), duration);
    await flush();
    controller.updateProgress(const Duration(seconds: 1421), duration);
    expect(loads, 1);
    expect(controller.hasError, isTrue);
    await controller.playNext();
    expect(loads, 2);
    expect(plays, 1);
    expect(controller.context!.index, 1);
  });

  test(
      'waits for in-flight prefetch, prevents double taps and ignores disposal',
      () async {
    final pending = Completer<PlaybackSource>();
    var loads = 0;
    var plays = 0;
    final controller = NextEpisodeController(
        context: contextAt(0),
        findEnding: (_, __) async => null,
        loadSource: (_) {
          loads++;
          return pending.future;
        },
        playSource: (_, __) async {
          plays++;
        });
    controller.updateProgress(const Duration(seconds: 1420), duration);
    final tap = controller.playNext();
    await controller.playNext();
    expect(loads, 1);
    controller.dispose();
    pending.complete(source);
    await tap;
    expect(plays, 0);
  });

  test('refreshes aged signed links and keeps the queue on playback failure',
      () async {
    var now = DateTime(2026);
    var loads = 0;
    var fails = true;
    final controller = NextEpisodeController(
        context: contextAt(0),
        now: () => now,
        findEnding: (_, __) async => null,
        loadSource: (_) async {
          loads++;
          return source;
        },
        playSource: (_, __) async {
          if (fails) throw Exception('expired');
        });
    addTearDown(controller.dispose);
    controller.updateProgress(const Duration(seconds: 1420), duration);
    await flush();
    now = now.add(const Duration(minutes: 3));
    await controller.playNext();
    expect(loads, 2);
    expect(controller.context!.index, 0);
    expect(controller.hasError, isTrue);
    fails = false;
    await controller.playNext();
    expect(loads, 3);
    expect(controller.context!.index, 1);
  });

  testWidgets(
      'overlay is tappable above the player and Keep watching dismisses',
      (tester) async {
    var plays = 0;
    var backgroundTaps = 0;
    final controller = NextEpisodeController(
        context: contextAt(0),
        endingStart: const Duration(seconds: 1300),
        findEnding: (_, __) async => null,
        loadSource: (_) async => source,
        playSource: (_, __) async {
          plays++;
        });
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Stack(children: [
      Positioned.fill(
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => backgroundTaps++,
              child: const ColoredBox(color: Colors.black))),
      NextEpisodeOverlay(controller: controller),
    ]))));
    controller.updateProgress(const Duration(seconds: 1301), duration);
    await tester.pumpAndSettle();
    expect(find.text('Ending credits'), findsOneWidget);
    await tester.tap(find.text('Play next'));
    await tester.pumpAndSettle();
    expect(plays, 1);
    expect(backgroundTaps, 0);
    controller.updateProgress(const Duration(seconds: 1430), duration);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep watching'));
    await tester.pumpAndSettle();
    expect(find.text('Play next'), findsNothing);
    expect(plays, 1);
  });

  testWidgets('opening overlay renders while recent context is loading',
      (tester) async {
    final controller = NextEpisodeController(
      context: null,
      opening: const SkipInterval(
        start: Duration(seconds: 30),
        end: Duration(seconds: 90),
      ),
      findEnding: (_, __) async => null,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: NextEpisodeOverlay(controller: controller)),
    ));

    controller.updateProgress(const Duration(seconds: 45), duration);
    await tester.pumpAndSettle();

    expect(find.text('Opening credits'), findsOneWidget);
    expect(find.text('Skip intro'), findsOneWidget);
  });

  testWidgets('portrait prompts sit above player controls in a compact card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = NextEpisodeController(
      context: contextAt(0),
      opening: const SkipInterval(
        start: Duration(seconds: 60),
        end: Duration(seconds: 100),
      ),
      endingStart: const Duration(seconds: 1300),
      findEnding: (_, __) async => null,
      loadSource: (_) async => source,
      playSource: (_, __) async {},
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Colors.black),
          NextEpisodeOverlay(controller: controller),
        ]),
      ),
    ));

    controller.updateProgress(const Duration(seconds: 80), duration);
    await tester.pumpAndSettle();
    final promptRect =
        tester.getRect(find.byKey(const ValueKey('vertical-playback-prompt')));
    expect(promptRect.center.dx, closeTo(195, 2));
    expect(promptRect.bottom, lessThan(764));
    expect(find.text('Skip intro'), findsOneWidget);

    controller.updateProgress(const Duration(seconds: 1300), duration);
    await tester.pumpAndSettle();
    expect(find.text('Episode 2'), findsOneWidget);
    expect(find.text('Play next'), findsOneWidget);
    expect(find.byTooltip('Keep watching'), findsOneWidget);
  });
}
