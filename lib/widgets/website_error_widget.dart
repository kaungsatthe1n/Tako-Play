import 'package:flutter/material.dart';
import '../theme/tako_theme.dart';

class WebsiteErrorWidget extends StatelessWidget {
  const WebsiteErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'We could not load this right now.',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/deku.gif'),
        const SizedBox(height: 20),
        Container(
          margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          alignment: Alignment.center,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TakoTheme.darkTextTheme.headlineMedium,
          ),
        ),
        if (onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
      ],
    );
  }
}
