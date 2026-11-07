import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/theme/tako_theme.dart';
import 'package:tako_play/widgets/update_alert_dialog.dart';

void main() {
  testWidgets('uses the dark release-card design and can be dismissed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TakoTheme.dark(),
        home: const _DialogLauncher(),
      ),
    );

    await tester.tap(find.text('Show update'));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateAlertDialog), findsOneWidget);
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('NEW RELEASE'), findsOneWidget);
    expect(
      find.text('Update now to get the latest improvements and fixes.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Update now'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAlertDialog), findsNothing);
  });
}

class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const UpdateAlertDialog(
                downloadLink: 'https://example.com/tako-play.apk',
              ),
            ),
            child: const Text('Show update'),
          ),
        ),
      );
}
