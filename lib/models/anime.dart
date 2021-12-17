class AnimeResults {
  List<Anime>? animeList;
  AnimeResults({required this.animeList});
}

class Anime {
  String? id; 
  String? name;
  String? imageUrl;
  String? episodeUrl;
  String? currentEp;

  Anime({
    this.id,
    this.name,
    this.imageUrl,
    this.currentEp,
    this.episodeUrl,
  });
}
