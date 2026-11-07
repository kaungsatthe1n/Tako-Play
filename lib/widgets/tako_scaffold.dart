import 'package:flutter/material.dart';

class TakoScaffoldWithBackButton extends StatelessWidget {
  const TakoScaffoldWithBackButton({
    super.key,
    required this.appBarTitle,
    required this.body,
    this.extendBodyBehindAppBar = false,
  });
  final String? appBarTitle;
  final Widget body;
  final bool extendBodyBehindAppBar;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: AppBar(
        backgroundColor: extendBodyBehindAppBar ? Colors.transparent : null,
        title: appBarTitle != null
            ? Text(
                appBarTitle!,
              )
            : null,
        leading: IconButton(
          // Pop the route directly so a visible GetX snackbar does not
          // consume the first back tap and leave the user on this screen.
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .28),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 19),
          ),
        ),
      ),
      body: body,
    );
  }
}
