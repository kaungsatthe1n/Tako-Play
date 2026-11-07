/// The subset of a GitHub release used by the in-app update prompt.
class Github {
  const Github({
    this.downloadLink,
    this.newFeatures,
    this.version,
  });

  final String? version;
  final String? newFeatures;
  final String? downloadLink;

  factory Github.fromJson(Map<String, dynamic> json) {
    String? downloadLink;
    final assets = json['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final value = asset['browser_download_url'];
        if (value is String && value.trim().isNotEmpty) {
          downloadLink = value.trim();
          break;
        }
      }
    }

    return Github(
      version: _nonEmptyString(json['tag_name']),
      newFeatures: _nonEmptyString(json['body']),
      downloadLink: downloadLink,
    );
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}
