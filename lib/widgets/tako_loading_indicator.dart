import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Small branded loader used for screen and player buffering states.
class TakoLoadingIndicator extends StatelessWidget {
  const TakoLoadingIndicator({super.key, this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              strokeWidth: size > 40 ? 4 : 3,
              strokeCap: StrokeCap.round,
              color: tkGradientBlue,
              backgroundColor: tkGradientBlue.withValues(alpha: .18),
            ),
          ),
          Container(
            width: size * .46,
            height: size * .46,
            decoration: const BoxDecoration(
              color: tkDarkBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, size: size * .28),
          ),
        ],
      ),
    );
  }
}

/// Centers a loader in the visible tab area rather than behind bottom navigation.
class TakoLoadingView extends StatelessWidget {
  const TakoLoadingView({super.key, this.avoidBottomNavigation = false});

  final bool avoidBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final navigationHeight = avoidBottomNavigation
        ? 68 + 12 + MediaQuery.paddingOf(context).bottom
        : 0.0;
    return Center(
      child: Transform.translate(
        offset: Offset(0, -navigationHeight / 2),
        child: const TakoLoadingIndicator(),
      ),
    );
  }
}
