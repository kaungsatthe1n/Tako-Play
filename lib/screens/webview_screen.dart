import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/tako_loading_indicator.dart';
import '../widgets/tako_play_web_view.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  var _isLoading = true;
  WebViewController? _webViewController;
  var _hasReleasedWebView = false;
  var _isClosing = false;

  List<String> get _mediaUrls {
    final arguments = Get.arguments;
    final values = arguments?['mediaUrls'] is List
        ? arguments!['mediaUrls'] as List
        : [arguments?['mediaUrl']];

    final playerUrls = <String>[];
    for (final value in values) {
      if (value is! String) continue;
      final uri = Uri.tryParse(value);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          !playerUrls.contains(value)) {
        playerUrls.add(value);
      }
    }
    return playerUrls;
  }

  String? get _episodeUrl {
    final value = Get.arguments?['episodeUrl'];
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri.toString()
        : null;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    unawaited(_releaseWebView());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrls = _mediaUrls;
    if (mediaUrls.isEmpty) return _invalidEmbed();

    return PopScope(
      // Let Android's system back button and iOS's edge-swipe gesture remove
      // this route immediately. Waiting for an embedded player to unload
      // first can leave the user stuck on this screen when that page hangs.
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _releasePlayerInBackground();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            TakoPlayWebView(
              initialUrl: mediaUrls.first,
              fallbackUrls: mediaUrls.skip(1).toList(growable: false),
              referrerUrl: _episodeUrl,
              onControllerCreated: (controller) =>
                  _webViewController = controller,
              onLoadingChanged: (isLoading) {
                if (mounted && _isLoading != isLoading) {
                  setState(() => _isLoading = isLoading);
                }
              },
            ),
            if (_isLoading)
              const IgnorePointer(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(child: TakoLoadingIndicator()),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: Semantics(
                  button: true,
                  label: 'Back to episode details',
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.62),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: _closePlayerAndPop,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: SafeArea(
                child: Semantics(
                  button: true,
                  label: 'Toggle fullscreen orientation',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleOrientation,
                    child: const SizedBox(width: 56, height: 56),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleOrientation() async {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    await SystemChrome.setPreferredOrientations(
      isLandscape
          ? [DeviceOrientation.portraitUp]
          : [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
  }

  Future<void> _releaseWebView() async {
    if (_hasReleasedWebView) return;
    _hasReleasedWebView = true;

    final controller = _webViewController;
    if (controller == null) return;
    try {
      // Replacing the document releases the embedded player before this route
      // is removed, preventing background playback after navigating back.
      await controller.loadHtmlString('<!doctype html><html></html>');
      await controller.clearCache();
    } catch (_) {
      // The platform view may already be gone during disposal.
    }
  }

  void _releasePlayerInBackground() {
    if (_isClosing) return;
    _isClosing = true;
    unawaited(_releaseWebView());
  }

  void _closePlayerAndPop() {
    _releasePlayerInBackground();
    Navigator.of(context).maybePop();
  }

  Widget _invalidEmbed() => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline_rounded,
                    color: Colors.white70, size: 44),
                const SizedBox(height: 14),
                const Text(
                  'This video link is unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: Get.back,
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
}
