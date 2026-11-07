import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../bindings/managers_binding.dart';
import '../theme/tako_theme.dart';
import '../utils/tako_route.dart';

Future<void> main() async {
  _configureApp();
  runApp(const MyApp());
}

void _configureApp() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialBinding});

  /// Allows integration tests to run the complete app with deterministic
  /// local dependencies instead of external catalog services.
  final Bindings? initialBinding;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TakoPlay',
      defaultTransition: Transition.cupertino,
      theme: TakoTheme.dark(),
      initialRoute: '/',
      initialBinding: initialBinding ?? ManagerBinding(),
      getPages: TakoRoute.pages,
    );
  }
}
