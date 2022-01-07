class Github {
  String? version;
  String? newFeatures;
  String? downloadLink;

  Github({
    this.downloadLink,
    this.newFeatures,
    this.version,
  });
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
  String? downLoadUrl;
  Assets({this.downLoadUrl});

  factory Assets.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return Assets(
        downLoadUrl: json['browser_download_url'],
      );
    }
    return Assets();
  }
}
