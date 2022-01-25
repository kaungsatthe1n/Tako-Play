
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PlotSummary extends StatelessWidget {
  const PlotSummary({
    Key? key,
    required this.summary,
  }) : super(key: key);
  final String summary;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      textColor: tkLightGreen,
      iconColor: tkLightGreen,
      title: const Text('Plot Summary'),
      childrenPadding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(summary),
        ),
      ],
    );
  }
}
