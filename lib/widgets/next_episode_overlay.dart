import 'package:flutter/material.dart';

import '../helpers/next_episode_controller.dart';
import '../models/playback_context.dart';
import '../utils/constants.dart';

/// Appears above the player controls in both inline and fullscreen routes.
class NextEpisodeOverlay extends StatelessWidget {
  const NextEpisodeOverlay({super.key, required this.controller});
  final NextEpisodeController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final next = controller.next;
          if (!controller.isVisible && !controller.isOpeningVisible) {
            return const SizedBox.shrink();
          }
          return LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxHeight > constraints.maxWidth
                    ? _buildVertical(context, next)
                    : _buildLandscape(context, next),
          );
        },
      );

  Widget _buildLandscape(BuildContext context, PlaybackContext? next) =>
      SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Material(
                color: tkDarkBlue.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(18),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.isOpeningVisible) ...[
                        const Text('Opening credits',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: controller.skipOpeningNow,
                          icon: const Icon(Icons.fast_forward_rounded),
                          label: const Text('Skip intro'),
                        ),
                      ],
                      if (controller.isOpeningVisible && controller.isVisible)
                        const Divider(color: Colors.white24, height: 20),
                      if (controller.isVisible && next != null) ...[
                        Text('Up next · Episode ${next.episode.number}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(next.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: tkMutedText, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(_statusText,
                            style: const TextStyle(
                                color: tkMutedText, fontSize: 12)),
                        const SizedBox(height: 10),
                        Wrap(spacing: 6, children: [
                          FilledButton.icon(
                            onPressed: controller.isSwitching
                                ? null
                                : controller.playNext,
                            icon: _nextIcon,
                            label: Text(_nextLabel),
                          ),
                          TextButton(
                            onPressed: controller.isSwitching
                                ? null
                                : controller.dismiss,
                            child: const Text('Keep watching'),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildVertical(BuildContext context, PlaybackContext? next) =>
      SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            // Keep the compact prompt clear of BetterPlayer's bottom controls.
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 104),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Material(
                key: const ValueKey('vertical-playback-prompt'),
                color: tkDarkBlue.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(20),
                elevation: 10,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.isOpeningVisible)
                        _VerticalPromptRow(
                          icon: Icons.fast_forward_rounded,
                          title: 'Opening credits',
                          action: FilledButton.icon(
                            onPressed: controller.skipOpeningNow,
                            icon: const Icon(Icons.skip_next_rounded, size: 19),
                            label: const Text('Skip intro'),
                          ),
                        ),
                      if (controller.isOpeningVisible && controller.isVisible)
                        const Divider(color: Colors.white24, height: 22),
                      if (controller.isVisible && next != null)
                        _VerticalPromptRow(
                          icon: Icons.queue_play_next_rounded,
                          title: 'Episode ${next.episode.number}',
                          detail: next.name,
                          status: _statusText,
                          action: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Keep watching',
                                onPressed: controller.isSwitching
                                    ? null
                                    : controller.dismiss,
                                icon: const Icon(Icons.close_rounded,
                                    color: tkMutedText),
                              ),
                              FilledButton.icon(
                                onPressed: controller.isSwitching
                                    ? null
                                    : controller.playNext,
                                icon: _nextIcon,
                                label: Text(_nextLabel),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  String get _statusText => controller.hasError
      ? 'Could not prepare this episode'
      : controller.isPreparing
          ? 'Preparing next episode…'
          : controller.hasEndingTiming
              ? 'Ending credits'
              : 'This episode is almost over';

  String get _nextLabel => controller.isSwitching
      ? 'Opening…'
      : controller.hasError
          ? 'Retry next'
          : 'Play next';

  Widget get _nextIcon => controller.isSwitching
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.skip_next_rounded);
}

class _VerticalPromptRow extends StatelessWidget {
  const _VerticalPromptRow({
    required this.icon,
    required this.title,
    required this.action,
    this.detail,
    this.status,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final String? status;
  final Widget action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                if (detail != null)
                  Text(detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tkMutedText, fontSize: 12)),
                if (status != null)
                  Text(status!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tkMutedText, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      );
}
