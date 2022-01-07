class AnimeResults {
  List<Anime>? animeList;
  AnimeResults({required this.animeList});
}

class Anime {
  String? id;
  String? name;
  String? imageUrl;
  String? summary;
  String? status;
  String? animeUrl;
  List<String>? genres;
  List<String>? epLinks;
  String? currentEp;
  String? releasedDate;

  Anime({
    this.id,
    this.name,
    this.imageUrl,
    this.status,
    this.summary,
    this.genres,
    this.epLinks,
    this.currentEp,
    this.animeUrl,
    this.releasedDate,
  });
}
