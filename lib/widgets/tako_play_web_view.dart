import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// A user-driven WebView for an externally hosted player.
///
/// It permits HTTPS redirects while the player is loading, then keeps later
/// top-level navigation on the resolved player host. It intentionally does not
/// alter the page DOM or synthesize player interactions.
class TakoPlayWebView extends StatefulWidget {
  const TakoPlayWebView({
    required this.initialUrl,
    required this.onLoadingChanged,
    this.fallbackUrls = const [],
    this.referrerUrl,
    this.onControllerCreated,
    super.key,
  });

  final String initialUrl;
  final ValueChanged<bool> onLoadingChanged;
  final List<String> fallbackUrls;
  final String? referrerUrl;
  final ValueChanged<WebViewController>? onControllerCreated;

  @override
  State<TakoPlayWebView> createState() => _TakoPlayWebViewState();
}

class _TakoPlayWebViewState extends State<TakoPlayWebView> {
  late final WebViewController _webViewController;
  final Set<String> _trustedPlayerHosts = <String>{};
  late final List<Uri> _playerUris;
  late final Map<String, String> _playerRequestHeaders;
  Uri? _activePageUri;
  var _playerIndex = 0;
  var _mainFrameNavigationLocked = false;
  var _hasReleasedPlayer = false;

  @override
  void initState() {
    super.initState();
    _playerUris = [widget.initialUrl, ...widget.fallbackUrls]
        .map(Uri.tryParse)
        .whereType<Uri>()
        .where((uri) => uri.scheme == 'https' && uri.host.isNotEmpty)
        .toList(growable: false);
    _playerRequestHeaders = playerRequestHeaders(widget.referrerUrl);
    final initialUri = _playerUris.first;
    _preparePlayerLoad(initialUri);

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              widget.onLoadingChanged(false);
            }
          },
          onHttpError: _onHttpError,
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(initialUri, headers: _playerRequestHeaders);
    widget.onControllerCreated?.call(_webViewController);
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null || !isAllowedPlayerNavigation(request.url)) {
      return NavigationDecision.prevent;
    }

    // Embedded media, captions, and player controls may use different HTTPS
    // origins. Only constrain navigations that could replace the app's player.
    if (!request.isMainFrame) return NavigationDecision.navigate;

    final host = uri.host.toLowerCase();
    if (!_mainFrameNavigationLocked) {
      _trustedPlayerHosts.add(host);
      return NavigationDecision.navigate;
    }

    return isTrustedPlayerHost(host, _trustedPlayerHosts)
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  void _onHttpError(HttpResponseError error) {
    final statusCode = error.response?.statusCode;
    final errorUri = error.request?.uri;
    final activePageUri = _activePageUri;
    if (!shouldTryNextPlayerEmbed(
      statusCode: statusCode,
      errorUri: errorUri,
      activePageUri: activePageUri,
      remainingPlayerUris: _playerUris.skip(_playerIndex + 1),
    )) {
      return;
    }

    _playerIndex += 1;
    final nextUri = _playerUris[_playerIndex];
    _preparePlayerLoad(nextUri);
    unawaited(
      _webViewController.loadRequest(nextUri, headers: _playerRequestHeaders),
    );
  }

  void _preparePlayerLoad(Uri uri) {
    _mainFrameNavigationLocked = false;
    _activePageUri = uri;
    _trustedPlayerHosts
      ..clear()
      ..add(uri.host.toLowerCase());
    widget.onLoadingChanged(true);
  }

  void _onPageStarted(String url) {
    final uri = Uri.tryParse(url);
    if (!_mainFrameNavigationLocked &&
        uri != null &&
        isAllowedPlayerNavigation(url)) {
      _trustedPlayerHosts.add(uri.host.toLowerCase());
      _activePageUri = uri;
    }
    widget.onLoadingChanged(true);
  }

  void _onPageFinished(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && isTrustedPlayerHost(uri.host, _trustedPlayerHosts)) {
      _mainFrameNavigationLocked = true;
    }
    widget.onLoadingChanged(false);
  }

  @override
  void deactivate() {
    // Start unloading while the platform view is still attached. Calling this
    // from the parent route's dispose is too late on iOS after an edge swipe,
    // allowing an embedded player to continue its audio in the background.
    _releasePlayer();
    super.deactivate();
  }

  @override
  void dispose() {
    _releasePlayer();
    super.dispose();
  }

  void _releasePlayer() {
    if (_hasReleasedPlayer) return;
    _hasReleasedPlayer = true;

    unawaited(
      _webViewController
          .loadHtmlString('<!doctype html><html><body></body></html>')
          .catchError((_) {
        // The native view can already be gone if the route was removed
        // without a transition. Either way, do not let cleanup throw.
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _webViewController);
  }
}

/// Limits automatic server changes to a permanently gone player document.
///
/// Some provider entries are wrapper pages that put another advertised player
/// in an iframe. In that case the wrapper is successful (200), while the
/// nested player is 410. Match that nested request only when it has the same
/// host and path as a remaining source-provided player. Errors from media
/// fragments, captions, and unrelated page resources do not cause a swap.
bool shouldTryNextPlayerEmbed({
  required int? statusCode,
  required Uri? errorUri,
  required Uri? activePageUri,
  required Iterable<Uri> remainingPlayerUris,
}) {
  if (statusCode != 410 || errorUri == null || activePageUri == null) {
    return false;
  }

  final remainingPlayers = remainingPlayerUris.toList(growable: false);
  if (remainingPlayers.isEmpty) return false;
  if (errorUri == activePageUri) return true;

  return remainingPlayers.any(
    (playerUri) =>
        errorUri.host.toLowerCase() == playerUri.host.toLowerCase() &&
        errorUri.path == playerUri.path,
  );
}

/// Player hosts commonly redirect through a regional edge, consent page, or
/// signed media host. Keep that normal HTTPS flow intact, but do not let a page
/// invoke app links, telephone links, or other non-web schemes.
bool isAllowedPlayerNavigation(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// Allows the resolved host and its subdomains, but not an unrelated page
/// opened by a player control after the embed has loaded.
bool isTrustedPlayerHost(String host, Set<String> trustedHosts) {
  final normalizedHost = host.toLowerCase();
  return trustedHosts.any(
    (trustedHost) =>
        normalizedHost == trustedHost ||
        normalizedHost.endsWith('.$trustedHost'),
  );
}

/// Builds the request context that a browser would normally include when an
/// advertised player iframe is opened from an episode page.
///
/// Invalid and non-HTTPS values are discarded rather than being forwarded to
/// a third-party player host.
Map<String, String> playerRequestHeaders(String? referrerUrl) {
  final uri = referrerUrl == null ? null : Uri.tryParse(referrerUrl);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return const <String, String>{};
  }
  return <String, String>{
    'Referer': uri.removeFragment().toString(),
  };
}
