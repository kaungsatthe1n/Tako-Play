class RecentAnime {
  RecentAnime({
    required this.currentEp,
    required this.id,
    required this.epUrl,
    required this.name,
    required this.imageUrl,
    this.animeUrl = '',
  });

  final String id;
  final String name;
  final String epUrl;
  final String currentEp;
  final String imageUrl;
  final String animeUrl;

  factory RecentAnime.fromJson(Map<String, dynamic> json) => RecentAnime(
        id: json['id'],
        name: json['name'],
        epUrl: json['epUrl'],
        currentEp: json['currentEp'],
        imageUrl: json['imageUrl'],
        animeUrl: json['animeUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'epUrl': epUrl,
        'currentEp': currentEp,
        'imageUrl': imageUrl,
        'animeUrl': animeUrl,
      };
}
