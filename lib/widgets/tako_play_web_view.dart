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
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Color.fromARGB(255, 255, 255, 255))
      ..loadRequest(Uri.parse(widget.initialUrl))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          if (widget.onLoadingFinished != null) {
            widget.onLoadingFinished!.call(_webViewController);
          }
        },
        onNavigationRequest: (request) {
          if (request.url == widget.initialUrl) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _webViewController,
    );
  }
}
