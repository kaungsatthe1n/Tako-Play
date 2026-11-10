import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Adds consistent tactile feedback to the app's content cards.
class TakoPressableCard extends StatefulWidget {
  const TakoPressableCard({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.enableInkFeedback = true,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final bool enableInkFeedback;

  @override
  State<TakoPressableCard> createState() => _TakoPressableCardState();
}

class _TakoPressableCardState extends State<TakoPressableCard> {
  var _isPressed = false;

  void _setPressed(bool value) {
    if (mounted && _isPressed != value) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? .975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          splashFactory: widget.enableInkFeedback
              ? InkRipple.splashFactory
              : NoSplash.splashFactory,
          splashColor: widget.enableInkFeedback
              ? tkGradientBlue.withValues(alpha: .22)
              : Colors.transparent,
          highlightColor: widget.enableInkFeedback
              ? Colors.white.withValues(alpha: .04)
              : Colors.transparent,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: widget.child,
        ),
      ),
    );
  }
}
