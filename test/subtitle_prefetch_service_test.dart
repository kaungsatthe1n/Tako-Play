import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tako_play/services/playback_service.dart';
import 'package:tako_play/services/subtitle_prefetch_service.dart';

void main() {
  test('prefetch keeps headers/defaults/timing and leaves failed tracks usable',
      () async {
    final service = SubtitlePrefetchService(client: MockClient((request) async {
      expect(request.headers['referer'], 'https://player.example/');
      return request.url.path.endsWith('en.vtt')
          ? http.Response('WEBVTT\n\n00:00.000 --> 00:01.000\nHello', 200)
          : http.Response('not found', 404);
    }));
    addTearDown(service.close);
    final source = await service.prepare(const PlaybackSource(
      url: 'https://cdn.example/master.m3u8',
      headers: {'Origin': 'source'},
      endingStart: Duration(seconds: 1300),
      subtitles: [
        PlaybackSubtitle(
            url: 'https://cdn.example/en.vtt',
            name: 'English',
            headers: {'Referer': 'https://player.example/'},
            selectedByDefault: true),
        PlaybackSubtitle(
            url: 'https://cdn.example/fr.vtt',
            name: 'French',
            headers: {'Referer': 'https://player.example/'}),
      ],
    ));
    expect(source.endingStart, const Duration(seconds: 1300));
    expect(source.headers['Origin'], 'source');
    expect(source.subtitles.first.content, contains('Hello'));
    expect(source.subtitles.first.selectedByDefault, isTrue);
    expect(source.subtitles.last.content, isNull);
    expect(source.subtitles.last.url, endsWith('fr.vtt'));
  });
}
