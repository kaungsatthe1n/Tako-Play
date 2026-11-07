import 'package:flutter/material.dart';

import '../utils/constants.dart';

class PlotSummary extends StatelessWidget {
  const PlotSummary({
    super.key,
    required this.summary,
  });
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tkDarkBlue.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: Colors.white,
        iconColor: tkCoral,
        collapsedIconColor: tkMutedText,
        title: const Text('About this title',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(summary,
              style: const TextStyle(color: tkMutedText, height: 1.5)),
        ],
      ),
    );
  }
}
