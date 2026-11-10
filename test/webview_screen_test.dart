import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tako_play/screens/webview_screen.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    WebViewPlatform.instance = _FakeWebViewPlatform();
    _FakeWebViewController.loadedUris.clear();
  });
  tearDown(() async => Get.reset());

  testWidgets('rejects an invalid player handoff URL', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: _LaunchWebView()));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('This video link is unavailable.'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
  });

  testWidgets('renders a valid player and accepts secure fallbacks',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const _LaunchWebView(),
        getPages: [],
      ),
    );
    unawaited(Get.to(
      () => const WebViewScreen(),
      arguments: {
        'mediaUrls': [
          'https://player.example/embed',
          'https://backup.example/embed',
          'http://ignored.example/embed',
          'https://player.example/embed',
        ],
        'episodeUrl': 'https://catalog.example/episode#watch',
      },
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(WebViewScreen), findsOneWidget);
    expect(
        find.bySemanticsLabel('Toggle fullscreen orientation'), findsOneWidget);
    expect(find.text('This video link is unavailable.'), findsNothing);
    expect(
      await _FakeWebViewPlatform.lastDelegate!.navigate(
        const NavigationRequest(
          url: 'https://redirect.example/player',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.navigate,
    );
    _FakeWebViewPlatform.lastDelegate!.pageStarted(
      'https://redirect.example/player',
    );
    _FakeWebViewPlatform.lastDelegate!.resourceError(
      const WebResourceError(
        errorCode: 1,
        description: 'offline',
        isForMainFrame: true,
      ),
    );
    _FakeWebViewPlatform.lastDelegate!.pageFinished(
      'https://player.example/embed',
    );
    await tester.pump();
    expect(
      await _FakeWebViewPlatform.lastDelegate!.navigate(
        const NavigationRequest(
          url: 'https://player.example/next',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await _FakeWebViewPlatform.lastDelegate!.navigate(
        const NavigationRequest(
          url: 'https://untrusted.example/next',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    _FakeWebViewPlatform.lastDelegate!.httpError(
      HttpResponseError(
        request:
            WebResourceRequest(uri: Uri.parse('https://backup.example/embed')),
        response: WebResourceResponse(
          uri: Uri.parse('https://backup.example/embed'),
          statusCode: 410,
        ),
      ),
    );
    await tester.pump();
    expect(_FakeWebViewController.loadedUris.last.host, 'backup.example');
    await tester.tap(find.bySemanticsLabel('Toggle fullscreen orientation'));
    await tester.pump();
    tester.view.physicalSize = const Size(1600, 800);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pump();
    Get.back();
    await tester.pumpAndSettle();
  });
}

class _LaunchWebView extends StatelessWidget {
  const _LaunchWebView();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => const WebViewScreen(),
              arguments: {'mediaUrl': 'intent://not-a-player'},
            ),
            child: const Text('Open'),
          ),
        ),
      );
}

class _FakeWebViewPlatform extends WebViewPlatform {
  static _FakeNavigationDelegate? lastDelegate;
  @override
  PlatformWebViewController createPlatformWebViewController(
          PlatformWebViewControllerCreationParams params) =>
      _FakeWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams params) =>
      _FakeWebViewWidget(params);

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
          PlatformWebViewCookieManagerCreationParams params) =>
      _FakeCookieManager(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
          PlatformNavigationDelegateCreationParams params) =>
      lastDelegate = _FakeNavigationDelegate(params);
}

class _FakeWebViewController extends PlatformWebViewController {
  _FakeWebViewController(super.params) : super.implementation();
  static final loadedUris = <Uri>[];
  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      loadedUris.add(params.uri);
  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}
  @override
  Future<void> setBackgroundColor(Color color) async {}
  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}
  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _FakeCookieManager extends PlatformWebViewCookieManager {
  _FakeCookieManager(super.params) : super.implementation();
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();
  PageEventCallback? _onPageFinished;
  PageEventCallback? _onPageStarted;
  NavigationRequestCallback? _onNavigationRequest;
  HttpResponseErrorCallback? _onHttpError;
  WebResourceErrorCallback? _onWebResourceError;

  void pageFinished(String url) => _onPageFinished?.call(url);
  void pageStarted(String url) => _onPageStarted?.call(url);
  Future<NavigationDecision> navigate(NavigationRequest request) =>
      Future.value(_onNavigationRequest!(request));
  void httpError(HttpResponseError error) => _onHttpError?.call(error);
  void resourceError(WebResourceError error) =>
      _onWebResourceError?.call(error);
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
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async =>
      _onWebResourceError = callback;
  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback callback) async =>
      _onHttpError = callback;
}
