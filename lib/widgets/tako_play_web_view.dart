import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// [TakoPlayWebView] is a webview specifically tailored for the needs of the
/// Tako Play app. Rather than always creating a webview and assigning it same
/// values each time, this widget can be instantiated without going though that
/// hassle.
class TakoPlayWebView extends StatefulWidget {
  const TakoPlayWebView({
    required this.initialUrl,
    this.onLoadingFinished,
    Key? key,
  }) : super(key: key);

  /// Initial url of the web view
  final String initialUrl;

  /// Callback triggered once the page has finished loading
  final Function(WebViewController)? onLoadingFinished;

  @override
  State<TakoPlayWebView> createState() => _TakoPlayWebViewState();
}

class _TakoPlayWebViewState extends State<TakoPlayWebView> {
  WebViewController? _webViewController;

  @override
  Widget build(BuildContext context) => WebView(
        initialUrl: widget.initialUrl,
        javascriptMode: JavascriptMode.unrestricted,
        allowsInlineMediaPlayback: true,
        backgroundColor: const Color(0x00000000),
        onWebViewCreated: (controller) async {
          _webViewController = controller;
        },
        onPageFinished: (_) async {
          if (_webViewController == null) return;
          widget.onLoadingFinished?.call(_webViewController!);
        },
        navigationDelegate: (NavigationRequest request) {
          // If we are navigating to the destination url, allow it.
          if (request.url == widget.initialUrl) {
            return NavigationDecision.navigate;
          }

          // Otherwise, reject any navigation to other web urls
          return NavigationDecision.prevent;
        },
      );
}
