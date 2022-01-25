class BookMark {
  String id;
  String name;
  String animeUrl;
  String imageUrl;

  BookMark(
      {required this.id,
      required this.name,
      required this.animeUrl,
      required this.imageUrl});

  factory BookMark.fromJson(Map<String, dynamic> json) => BookMark(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        animeUrl: json['animeUrl'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'animeUrl': animeUrl,
      };
}
