import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

/// A compact prompt for the latest stable TakoPlay release.
class UpdateAlertDialog extends StatelessWidget {
  const UpdateAlertDialog({
    super.key,
    required this.downloadLink,
    this.isDirectApkDownload = false,
  });

  final String downloadLink;
  final bool isDirectApkDownload;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: screenHeight * .82,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tkDarkBlue,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: tkSurfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .42),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: tkGradientBlue.withValues(alpha: .12),
                blurRadius: 32,
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Semantics(
              namesRoute: true,
              label: 'Stable TakoPlay update available',
              child: Stack(
                children: [
                  Positioned(
                    top: -94,
                    right: -66,
                    child: IgnorePointer(
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              tkGradientBlue.withValues(alpha: .2),
                              tkGradientBlue.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: tkGradientBlue.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: tkGradientBlue.withValues(alpha: .32),
                                ),
                              ),
                              child: const Icon(
                                Icons.system_update_alt_rounded,
                                color: Color(0xFFB9AEFF),
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Close update prompt',
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: tkSurface,
                                foregroundColor: tkMutedText,
                                fixedSize: const Size(40, 40),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 19),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'TAKOPLAY UPDATE',
                          style: textTheme.labelMedium?.copyWith(
                            color: Color(0xFFB9AEFF),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A new version is ready',
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 25,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Get the latest improvements and fixes with the newest release.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: tkMutedText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: tkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: tkSurfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: tkGradientBlue,
                                size: 21,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STABLE RELEASE',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .8,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isDirectApkDownload
                                          ? 'Official APK download'
                                          : 'Official GitHub release page',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: tkMutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => _launchUrl(downloadLink),
                            style: FilledButton.styleFrom(
                              backgroundColor: tkGradientBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: Icon(
                              isDirectApkDownload
                                  ? Icons.download_rounded
                                  : Icons.open_in_new_rounded,
                              size: 19,
                            ),
                            label: Text(isDirectApkDownload
                                ? 'Download APK'
                                : 'View release'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: tkMutedText,
                              minimumSize: const Size.fromHeight(44),
                            ),
                            child: const Text('Maybe later'),
                          ),
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
    );
  }
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
