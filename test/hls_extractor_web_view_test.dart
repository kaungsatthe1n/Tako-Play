import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/services/playback_service.dart';
import 'package:tako_play/widgets/hls_extractor_web_view.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  setUp(() {
    WebViewPlatform.instance = _FakeHlsWebViewPlatform();
    _FakeHlsWebViewController.last = null;
    _FakeHlsNavigationDelegate.last = null;
  });

  group('parseHlsExtractorMessage', () {
    test('parses opening and ending markers exposed by the player', () {
      final message = parseHlsExtractorMessage(
        jsonEncode({
          'type': 'hls',
          'url': 'https://cdn.example.com/video/master.m3u8',
          'pageUrl': 'https://player.example.com/stream/123/sub',
          'opening': {'start': 0, 'end': 107},
          'ending': {'start': 1300, 'end': 1390},
        }),
      );

      expect(message?.opening?.start, Duration.zero);
      expect(message?.opening?.end, const Duration(seconds: 107));
      expect(message?.endingStart, const Duration(seconds: 1300));
    });

    test('accepts a signed HTTPS HLS resource and its final page URL', () {
      final message = parseHlsExtractorMessage(
        jsonEncode({
          'type': 'hls',
          'url': 'https://cdn.example.com/video/master.m3u8?token=signed',
          'pageUrl': 'https://player.example.com/stream/123/sub',
          'subtitles': [
            {
              'url': 'https://cdn.example.com/video/captions/en.vtt',
              'name': 'English',
              'default': true,
            },
            {
              'url': 'https://cdn.example.com/video/captions/extra.vtt',
            },
          ],
        }),
      );

      expect(message, isNotNull);
      expect(message!.type, HlsExtractorMessageType.hls);
      expect(
        message.url.toString(),
        'https://cdn.example.com/video/master.m3u8?token=signed',
      );
      expect(message.pageUrl, 'https://player.example.com/stream/123/sub');
      expect(message.subtitles, hasLength(2));
      expect(message.subtitles.first.url,
          'https://cdn.example.com/video/captions/en.vtt');
      expect(message.subtitles.first.name, 'English');
      expect(message.subtitles.first.selectedByDefault, isTrue);
      expect(message.subtitles.last.name, 'Subtitle 1');
    });

    test('accepts the wrapper handoff to its advertised embedded player', () {
      final message = parseHlsExtractorMessage(
        jsonEncode({
          'type': 'embed',
          'url': 'https://player.example.com/stream/123/sub',
          'pageUrl': 'https://play.gogoanimes.org/watch',
        }),
      );

      expect(message, isNotNull);
      expect(message!.type, HlsExtractorMessageType.embed);
      expect(message.url.host, 'player.example.com');
    });

    test('rejects insecure, non-HLS, and malformed messages', () {
      expect(
        parseHlsExtractorMessage(
          jsonEncode({
            'type': 'hls',
            'url': 'http://cdn.example.com/master.m3u8',
          }),
        ),
        isNull,
      );
      expect(
        parseHlsExtractorMessage(
          jsonEncode({
            'type': 'hls',
            'url': 'https://cdn.example.com/video.mp4',
          }),
        ),
        isNull,
      );
      expect(parseHlsExtractorMessage('not-json'), isNull);
      expect(parseHlsExtractorMessage('{"type":"unknown"}'), isNull);
    });

    test('keeps supported SRT and TTML tracks while rejecting bad tracks', () {
      final message = parseHlsExtractorMessage(
        jsonEncode({
          'type': 'hls',
          'url': 'https://cdn.example.com/master.m3u8',
          'subtitles': [
            {'url': 'https://cdn.example.com/one.srt'},
            {'url': 'https://cdn.example.com/two.ttml', 'name': 'Two'},
            {'url': 'http://cdn.example.com/unsafe.vtt'},
            {'url': 'https://cdn.example.com/ignored.txt'},
            'not a track',
          ],
        }),
      );

      expect(
          message!.subtitles.map((track) => track.name), ['Subtitle 1', 'Two']);
    });

    testWidgets('hands an embed and HLS source off from its WebView',
        (tester) async {
      PlaybackSource? source;
      var failed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HlsExtractorWebView(
            playerUrl: 'https://play.gogoanimes.org/watch#episode',
            referrerUrl: 'https://catalog.example/episode#fragment',
            onSourceFound: (value) => source = value,
            onFailure: () => failed = true,
          ),
        ),
      );
      await tester.pump();
      final controller = _FakeHlsWebViewController.last!;
      final delegate = _FakeHlsNavigationDelegate.last!;
      expect(controller.loaded.single.toString(),
          'https://play.gogoanimes.org/watch#episode');
      expect(
        await delegate.navigate(const NavigationRequest(
          url: 'http://unsafe.example',
          isMainFrame: true,
        )),
        NavigationDecision.prevent,
      );
      delegate.pageStarted('https://play.gogoanimes.org/watch');
      delegate.pageFinished('https://play.gogoanimes.org/watch');
      await tester.pump();
      expect(controller.javascriptRuns, 1);

      controller.send(jsonEncode({
        'type': 'embed',
        'url': 'https://player.example.com/embed',
      }));
      await tester.pump();
      expect(controller.loaded.last.host, 'player.example.com');

      controller.send(jsonEncode({
        'type': 'hls',
        'url': 'https://cdn.example.com/master.m3u8',
        'pageUrl': 'https://player.example.com/embed',
        'subtitles': [
          {'url': 'https://cdn.example.com/en.vtt', 'name': 'English'},
        ],
      }));
      await tester.pump();
      expect(failed, isFalse);
      expect(source!.url, 'https://cdn.example.com/master.m3u8');
      expect(source!.headers['Referer'], 'https://player.example.com/');
      expect(source!.subtitles.single.name, 'English');

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(controller.released, isTrue);
    });

    testWidgets('reports a timeout when no player source is exposed',
        (tester) async {
      var failures = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: HlsExtractorWebView(
            playerUrl: 'https://player.example/embed',
            referrerUrl: 'https://catalog.example/episode',
            onSourceFound: (_) => fail('unexpected source'),
            onFailure: () => failures++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 31));
      expect(failures, 1);
    });
  });
}

class _FakeHlsWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
          PlatformWebViewControllerCreationParams params) =>
      _FakeHlsWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _FakeHlsWebViewWidget(params);

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams params) =>
      _FakeHlsCookieManager(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams params) =>
      _FakeHlsNavigationDelegate(params);
}

class _FakeHlsWebViewController extends PlatformWebViewController {
  _FakeHlsWebViewController(super.params) : super.implementation() {
    last = this;
  }

  static _FakeHlsWebViewController? last;
  final loaded = <Uri>[];
  JavaScriptChannelParams? _channel;
  var javascriptRuns = 0;
  var released = false;

  void send(String message) =>
      _channel!.onMessageReceived(JavaScriptMessage(message: message));

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      _channel = params;
  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      loaded.add(params.uri);
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async =>
      released = true;
  @override
  Future<void> runJavaScript(String javaScript) async => javascriptRuns++;
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}
}

class _FakeHlsWebViewWidget extends PlatformWebViewWidget {
  _FakeHlsWebViewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakeHlsCookieManager extends PlatformWebViewCookieManager {
  _FakeHlsCookieManager(super.params) : super.implementation();
}

class _FakeHlsNavigationDelegate extends PlatformNavigationDelegate {
  _FakeHlsNavigationDelegate(super.params) : super.implementation() {
    last = this;
  }

  static _FakeHlsNavigationDelegate? last;
  PageEventCallback? _onPageStarted;
  PageEventCallback? _onPageFinished;
  NavigationRequestCallback? _onNavigationRequest;

  void pageStarted(String url) => _onPageStarted?.call(url);
  void pageFinished(String url) => _onPageFinished?.call(url);
  Future<NavigationDecision> navigate(NavigationRequest request) =>
      Future.value(_onNavigationRequest!(request));

  @override
  Future<void> setOnNavigationRequest(
          NavigationRequestCallback callback) async =>
      _onNavigationRequest = callback;
  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async =>
      _onPageStarted = callback;
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async =>
      _onPageFinished = callback;
}
