/// The subset of a GitHub release used by the in-app update prompt.
class Github {
  const Github({
    this.downloadLink,
    this.apkDownloadLink,
    this.releasePageUrl,
    this.newFeatures,
    this.version,
    this.isPrerelease = false,
    this.isDraft = false,
  });

  final String? version;
  final String? newFeatures;

  /// First available release asset, retained for generic-platform fallback.
  final String? downloadLink;
  final String? apkDownloadLink;
  final String? releasePageUrl;
  final bool isPrerelease;
  final bool isDraft;

  factory Github.fromJson(Map<String, dynamic> json) {
    String? downloadLink;
    String? apkDownloadLink;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final value = asset['browser_download_url'];
        if (value is String && value.trim().isNotEmpty) {
          final url = value.trim();
          downloadLink ??= url;
          final assetName = _nonEmptyString(asset['name'])?.toLowerCase();
          final isApk =
              Uri.tryParse(url)?.path.toLowerCase().endsWith('.apk') == true ||
                  assetName?.endsWith('.apk') == true;
          if (isApk) apkDownloadLink ??= url;
        }
      }
    }

    return Github(
      version: _nonEmptyString(json['tag_name']),
      newFeatures: _nonEmptyString(json['body']),
      downloadLink: downloadLink,
      apkDownloadLink: apkDownloadLink,
      releasePageUrl: _nonEmptyString(json['html_url']),
      isPrerelease: json['prerelease'] == true,
      isDraft: json['draft'] == true,
    );
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}
