import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../services/playback_service.dart';
import '../utils/constants.dart';

/// Runs a dynamic embedded player only until it exposes its signed HLS URL.
///
/// Some players generate the CDN token in obfuscated JavaScript. Observing the
/// resulting resource URL is more reliable and maintainable than copying that
/// signing implementation into the app. The widget is intended to be offstage;
/// playback itself is handed to Better Player as soon as a manifest is found.
class HlsExtractorWebView extends StatefulWidget {
  const HlsExtractorWebView({
    required this.playerUrl,
    required this.referrerUrl,
    required this.onSourceFound,
    required this.onFailure,
    super.key,
  });

  final String playerUrl;
  final String referrerUrl;
  final ValueChanged<PlaybackSource> onSourceFound;
  final VoidCallback onFailure;

  @override
  State<HlsExtractorWebView> createState() => _HlsExtractorWebViewState();
}

class _HlsExtractorWebViewState extends State<HlsExtractorWebView> {
  late final WebViewController _controller;
  late final Timer _timeout;
  final Set<String> _visitedPages = <String>{};
  Uri? _activePageUri;
  var _completed = false;
  var _released = false;

  @override
  void initState() {
    super.initState();
    final initialUri = Uri.parse(widget.playerUrl);
    final referrerUri = Uri.parse(widget.referrerUrl).removeFragment();
    _activePageUri = initialUri;
    _visitedPages.add(initialUri.toString());

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'TakoHlsExtractor',
        onMessageReceived: _handleMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(
        initialUri,
        headers: {
          'Referer': referrerUri.toString(),
          'User-Agent': userAgent,
        },
      );
    _timeout = Timer(const Duration(seconds: 30), _fail);
  }

  void _onPageStarted(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'https') _activePageUri = uri;
  }

  void _onPageFinished(String url) {
    if (_completed) return;
    unawaited(
      _controller.runJavaScript(_extractionScript).catchError((_) {
        // A navigation can detach the document while injection is starting.
      }),
    );
  }

  void _handleMessage(JavaScriptMessage message) {
    if (_completed) return;
    final update = parseHlsExtractorMessage(message.message);
    if (update == null) return;

    switch (update.type) {
      case HlsExtractorMessageType.hls:
        final pageUri = Uri.tryParse(update.pageUrl ?? '');
        if (pageUri == null ||
            pageUri.scheme != 'https' ||
            pageUri.host.isEmpty) {
          return;
        }
        _completed = true;
        _timeout.cancel();
        widget.onSourceFound(
          PlaybackSource(
            url: update.url.toString(),
            headers: {
              // Cross-origin media requests use the player's origin as their
              // referrer. Sending the full stream path is rejected by the CDN.
              'Referer': '${pageUri.origin}/',
              'User-Agent': userAgent,
            },
            subtitles: update.subtitles
                .map(
                  (subtitle) => PlaybackSubtitle(
                    url: subtitle.url,
                    name: subtitle.name,
                    selectedByDefault: subtitle.selectedByDefault,
                    headers: {
                      'Referer': '${pageUri.origin}/',
                      'User-Agent': userAgent,
                    },
                  ),
                )
                .toList(growable: false),
          ),
        );
      case HlsExtractorMessageType.embed:
        final activePage = _activePageUri;
        // Only the catalog wrapper is followed automatically. Unrelated ad or
        // tracking iframes in the final player must not become the main page.
        if (activePage == null ||
            activePage.host.toLowerCase() != 'play.gogoanimes.org' ||
            activePage.path != '/watch' ||
            !_visitedPages.add(update.url.toString())) {
          return;
        }
        _activePageUri = update.url;
        unawaited(
          _controller.loadRequest(
            update.url,
            headers: {
              'Referer': activePage.removeFragment().toString(),
              'User-Agent': userAgent,
            },
          ),
        );
    }
  }

  void _fail() {
    if (_completed) return;
    _completed = true;
    widget.onFailure();
  }

  @override
  void deactivate() {
    _release();
    super.deactivate();
  }

  @override
  void dispose() {
    _timeout.cancel();
    _release();
    super.dispose();
  }

  void _release() {
    if (_released) return;
    _released = true;
    unawaited(
      _controller
          .loadHtmlString('<!doctype html><html></html>')
          .catchError((_) {
        // The native view may already have been removed during route teardown.
      }),
    );
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

enum HlsExtractorMessageType { hls, embed }

class HlsExtractorMessage {
  const HlsExtractorMessage({
    required this.type,
    required this.url,
    this.pageUrl,
    this.subtitles = const [],
  });

  final HlsExtractorMessageType type;
  final Uri url;
  final String? pageUrl;
  final List<HlsExtractorSubtitle> subtitles;
}

class HlsExtractorSubtitle {
  const HlsExtractorSubtitle({
    required this.url,
    required this.name,
    required this.selectedByDefault,
  });

  final String url;
  final String name;
  final bool selectedByDefault;
}

HlsExtractorMessage? parseHlsExtractorMessage(String value) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) return null;
    final type = switch (decoded['type']) {
      'hls' => HlsExtractorMessageType.hls,
      'embed' => HlsExtractorMessageType.embed,
      _ => null,
    };
    if (type == null) return null;
    final url = Uri.tryParse(decoded['url']?.toString() ?? '');
    if (url == null || url.scheme != 'https' || url.host.isEmpty) return null;
    if (type == HlsExtractorMessageType.hls &&
        !url.path.toLowerCase().endsWith('.m3u8')) {
      return null;
    }
    final subtitles = <HlsExtractorSubtitle>[];
    var unnamedSubtitleNumber = 0;
    final rawSubtitles = decoded['subtitles'];
    if (rawSubtitles is List) {
      for (final rawSubtitle in rawSubtitles) {
        if (rawSubtitle is! Map) continue;
        final subtitleUrl = rawSubtitle['url']?.toString();
        final subtitleUri =
            subtitleUrl == null ? null : Uri.tryParse(subtitleUrl);
        if (subtitleUri == null ||
            subtitleUri.scheme != 'https' ||
            subtitleUri.host.isEmpty ||
            !_isSupportedSubtitleUri(subtitleUri)) {
          continue;
        }
        final name = rawSubtitle['name']?.toString().trim();
        final resolvedName = name == null || name.isEmpty
            ? 'Subtitle ${++unnamedSubtitleNumber}'
            : name;
        subtitles.add(
          HlsExtractorSubtitle(
            url: subtitleUri.toString(),
            name: resolvedName,
            selectedByDefault: rawSubtitle['default'] == true,
          ),
        );
      }
    }
    return HlsExtractorMessage(
      type: type,
      url: url,
      pageUrl: decoded['pageUrl']?.toString(),
      subtitles: subtitles,
    );
  } on FormatException {
    return null;
  }
}

bool _isSupportedSubtitleUri(Uri uri) {
  final path = uri.path.toLowerCase();
  return path.endsWith('.vtt') ||
      path.endsWith('.srt') ||
      path.endsWith('.ttml');
}

const _extractionScript = r'''
(() => {
  const findHls = () => {
    const urls = performance.getEntriesByType('resource').map(entry => entry.name);
    for (const element of document.querySelectorAll('video, source')) {
      const value = element.currentSrc || element.src;
      if (value) urls.push(value);
    }
    const manifests = [];
    for (const value of urls) {
      try {
        const uri = new URL(value, location.href);
        if (uri.protocol === 'https:' && uri.pathname.toLowerCase().endsWith('.m3u8')) {
          manifests.push(uri.href);
        }
      } catch (_) {}
    }
    return manifests.find(value => new URL(value).pathname.toLowerCase().endsWith('/master.m3u8')) || manifests[0];
  };

  const findSubtitles = () => {
    const tracks = [];
    const nextUnnamedTrackNumber = () => tracks.filter(track => /^Subtitle \d+$/.test(track.name)).length + 1;
  const add = (value, name = '', isDefault = false) => {
      try {
        const url = new URL(value, location.href);
        if (!/^https:$/.test(url.protocol) || !/\.(vtt|srt|ttml)$/i.test(url.pathname)) return;
        if (!tracks.some(track => track.url === url.href)) {
          tracks.push({url: url.href, name: name || `Subtitle ${nextUnnamedTrackNumber()}`, default: !!isDefault});
        }
      } catch (_) {}
    };

    for (const track of document.querySelectorAll('track[kind="subtitles"], track[kind="captions"]')) {
      add(track.src, track.label || track.srclang, track.default);
    }
    for (const entry of performance.getEntriesByType('resource')) {
      add(entry.name);
    }
    try {
      const player = window.jwplayer && window.jwplayer();
      const captions = player && player.getCaptionsList && player.getCaptionsList();
      if (Array.isArray(captions)) {
        for (const caption of captions) {
          add(caption.file || caption.src, caption.label || caption.name, caption.default);
        }
      }
    } catch (_) {}

    const matches = document.documentElement.innerHTML.matchAll(/["']([^"']+\.(?:vtt|srt|ttml)(?:\?[^"']*)?)["']/gi);
    for (const match of matches) add(match[1]);
    return tracks;
  };

  // Some players do not generate their signed manifest until playback starts.
  // Muted autoplay is sufficient; the offstage player is discarded on handoff.
  setTimeout(() => {
    if (findHls()) return;
    let started = false;
    try {
      const player = window.jwplayer && window.jwplayer();
      if (player) {
        player.setMute(true);
        const result = player.play();
        if (result && result.catch) result.catch(() => {});
        started = true;
      }
    } catch (_) {}
    if (!started) {
      for (const video of document.querySelectorAll('video')) {
        try {
          video.muted = true;
          const result = video.play();
          if (result && result.catch) result.catch(() => {});
        } catch (_) {}
      }
    }
  }, 3000);

  const timer = setInterval(() => {
    const manifest = findHls();
    if (manifest) {
      clearInterval(timer);
      TakoHlsExtractor.postMessage(JSON.stringify({
        type: 'hls', url: manifest, pageUrl: location.href,
        subtitles: findSubtitles()
      }));
      return;
    }
    if (location.hostname === 'play.gogoanimes.org' && location.pathname === '/watch') {
      const frame = document.querySelector('iframe[src]');
      if (frame) {
        clearInterval(timer);
        TakoHlsExtractor.postMessage(JSON.stringify({
          type: 'embed', url: frame.src, pageUrl: location.href
        }));
      }
    }
  }, 400);
  setTimeout(() => clearInterval(timer), 20000);
})();
''';
