import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../widgets/tako_loading_indicator.dart';
import '../widgets/tako_play_web_view.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  var _isLoading = true;
  var _isLandscape = false;

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
    ]);
  }

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: OrientationBuilder(
          builder: (context, orientation) {
            _updatePlayerOrientation(orientation);

            // Keep the compact portrait player from the v1.6.3 design.
            // Landscape expands to a familiar 16:9 viewing surface.
            final aspectRatio =
                orientation == Orientation.landscape ? 16 / 9 : 4 / 2.885;

            return AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TakoPlayWebView(
                    initialUrl: mediaUrls.first,
                    fallbackUrls: mediaUrls.skip(1).toList(growable: false),
                    referrerUrl: _episodeUrl,
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
                    bottom: 0,
                    left: 0,
                    right: 10,
                    child: SizedBox(
                      height: 50,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          button: true,
                          label: 'Toggle fullscreen orientation',
                          child: IconButton(
                            tooltip: 'Toggle fullscreen orientation',
                            onPressed: _toggleOrientation,
                            icon: const Icon(
                              Icons.zoom_out_map_outlined,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggleOrientation() async {
    await SystemChrome.setPreferredOrientations(
      _isLandscape
          ? [DeviceOrientation.portraitUp]
          : [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );
  }

  void _updatePlayerOrientation(Orientation orientation) {
    final isLandscape = orientation == Orientation.landscape;
    if (_isLandscape == isLandscape) return;

    _isLandscape = isLandscape;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          isLandscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        ),
      );
    });
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
