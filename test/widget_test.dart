import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/utils/routes.dart';

void main() {
  test('the app exposes its main navigation route', () {
    expect(Routes.mainScreen, '/');
  });
}
