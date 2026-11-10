import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:tako_play/services/playback_service.dart';
import 'package:tako_play/widgets/hls_extractor_web_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live wrapper extracts signed HLS and initializes Better Player',
    (tester) async {
      PlaybackSource? source;
      String? extractionFailure;
      await tester.pumpWidget(
        MaterialApp(
          home: Offstage(
            child: SizedBox(
              width: 1,
              height: 1,
              child: HlsExtractorWebView(
                playerUrl:
                    'https://play.gogoanimes.org/watch#AUPZqqyK6n0DLYg_OfdX32mG6Co073ErIgH4ZV3Ls_tg8Zhweg.1180.2.sub',
                referrerUrl: 'https://gogoanimes.org/watch/one-piece-5773/',
                onSourceFound: (value) => source = value,
                onFailure: () => extractionFailure = 'Extraction timed out.',
              ),
            ),
          ),
        ),
      );

      for (var i = 0;
          i < 40 && source == null && extractionFailure == null;
          i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(extractionFailure, isNull);
      expect(source, isNotNull);
      expect(Uri.parse(source!.url).path, endsWith('.m3u8'));
      expect(source!.headers['Referer'], isNotEmpty);

      const webKitUserAgent =
          'Mozilla/5.0 (iPhone; CPU iPhone OS 26_4 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.4 '
          'Mobile/15E148 Safari/604.1';
      final pageUri = Uri.parse(source!.headers['Referer']!);
      final originReferrer = '${pageUri.origin}/';
      final candidates = <String, Map<String, String>>{
        'captured': source!.headers,
        'origin + app UA': {
          'Referer': originReferrer,
          'User-Agent': source!.headers['User-Agent']!,
        },
        'origin + WebKit UA': {
          'Referer': originReferrer,
          'User-Agent': webKitUserAgent,
        },
        'full page + WebKit UA': {
          'Referer': pageUri.toString(),
          'User-Agent': webKitUserAgent,
        },
        'WebKit UA only': const {'User-Agent': webKitUserAgent},
        'no headers': const {},
      };
      Map<String, String>? workingHeaders;
      for (final candidate in candidates.entries) {
        try {
          final response = await http
              .get(Uri.parse(source!.url), headers: candidate.value)
              .timeout(const Duration(seconds: 10));
          debugPrint(
              'HLS header check ${candidate.key}: ${response.statusCode}');
          if (response.statusCode == 200) {
            workingHeaders ??= candidate.value;
          }
        } catch (error) {
          debugPrint('HLS header check ${candidate.key}: $error');
        }
      }
      expect(workingHeaders, isNotNull);

      final manifestUri = Uri.parse(source!.url);
      final masterResponse = await http.get(
        manifestUri,
        headers: workingHeaders,
      );
      debugPrint('HLS selected master: ${masterResponse.statusCode}');
      final variantPath =
          masterResponse.body.split('\n').map((line) => line.trim()).firstWhere(
                (line) => line.isNotEmpty && !line.startsWith('#'),
                orElse: () => '',
              );
      if (variantPath.isNotEmpty) {
        final variantUri = manifestUri.resolve(variantPath);
        final variantResponse = await http.get(
          variantUri,
          headers: workingHeaders,
        );
        debugPrint('HLS selected variant: ${variantResponse.statusCode}');
        final segmentPath = variantResponse.body
            .split('\n')
            .map((line) => line.trim())
            .firstWhere(
              (line) => line.isNotEmpty && !line.startsWith('#'),
              orElse: () => '',
            );
        if (segmentPath.isNotEmpty) {
          final segmentResponse = await http.get(
            variantUri.resolve(segmentPath),
            headers: workingHeaders,
          );
          debugPrint('HLS selected segment: ${segmentResponse.statusCode}');
        }
      }

      final initialized = Completer<void>();
      final playbackErrors = <String>[];
      final controller = BetterPlayerController(
        const PlayerConfiguration(autoPlay: true, autoDispose: false),
        betterPlayerDataSource: PlayerDataSource(
          DataSourceType.network,
          source!.url,
          videoFormat: VideoFormat.hls,
          headers: workingHeaders!,
        ),
      );
      controller.addEventsListener((event) {
        if (event.betterPlayerEventType == PlayerEventType.initialized &&
            !initialized.isCompleted) {
          initialized.complete();
        }
        if (event.betterPlayerEventType == PlayerEventType.exception) {
          playbackErrors.add(event.parameters?.toString() ?? 'Unknown error');
        }
      });
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: BetterPlayer(controller: controller)),
      );
      for (var i = 0; i < 45 && !initialized.isCompleted; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(playbackErrors, isEmpty);
      expect(initialized.isCompleted, isTrue);
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
