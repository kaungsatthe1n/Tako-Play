class RecentAnime {
  String id;
  String name;
  String epUrl;
  String currentEp;
  String imageUrl;
  // String animeUrl;

  RecentAnime({
    required this.currentEp,
    required this.id,
    required this.epUrl,
    required this.name,
    required this.imageUrl,
    // required this.animeUrl,
  });

  factory RecentAnime.fromJson(Map<String, dynamic> json) => RecentAnime(
        id: json['id'],
        name: json['name'],
        epUrl: json['epUrl'],
        currentEp: json['currentEp'],
        imageUrl: json['imageUrl'],
        // animeUrl: json['animeUrl'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'epUrl': epUrl,
        'currentEp': currentEp,
        'imageUrl': imageUrl,
        // 'animeUrl': animeUrl,
      };
}
