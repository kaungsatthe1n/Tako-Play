class Github {
  Github({
    this.downloadLink,
    this.newFeatures,
    this.version,
  });

  final String? version;
  final String? newFeatures;
  final String? downloadLink;

  factory Github.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return Github(
        version: json['tag_name'],
        newFeatures: json['body'],
        downloadLink: (json['assets'] as List<dynamic>)
            .map((e) => Assets.fromJson(e as Map<String, dynamic>))
            .toList()
            .first
            .downLoadUrl,
      );
    }
    return Github();
  }
}

class Assets {
  Assets({
    this.downLoadUrl,
  });

  final String? downLoadUrl;

  factory Assets.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return Assets(
        downLoadUrl: json['browser_download_url'],
      );
    }
    return Assets();
  }
}
