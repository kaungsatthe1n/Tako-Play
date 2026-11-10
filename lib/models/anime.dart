import '../utils/constants.dart';

class AnimeResults {
  const AnimeResults({
    required this.animeList,
  });

  final List<Anime> animeList;
}

class Anime {
  const Anime({
    this.id = '',
    this.name = '',
    this.imageUrl = '',
    this.status = '',
    this.summary = '',
    this.genres = const [],
    this.episodes = const [],
    this.currentEp = '',
    this.animeUrl = '',
    this.releasedDate = '',
  });

  final String id;
  final String name;
  final String imageUrl;
  final String summary;
  final String status;
  final String animeUrl;
  final List<Genre> genres;
  final List<Episode> episodes;
  final String currentEp;
  final String releasedDate;
}

class Genre {
  final String name;
  final String link;

  Genre({required this.name, required this.link});
}

class Episode {
  final String number;
  final String link;

  Episode({required this.link, required this.number});
}

final List<Genre> genreList = [
  Genre(name: 'Action', link: ACTION),
  Genre(name: 'Adventure', link: ADVENTURE),
  Genre(name: 'Comedy', link: COMEDY),
  Genre(name: 'Drama', link: DRAMA),
  Genre(name: 'Ecchi', link: ECCHI),
  Genre(name: 'Fantasy', link: FANTASY),
  Genre(name: 'Horror', link: HORROR),
  Genre(name: 'Mahou Shoujo', link: '$sourceBaseUrl/genre/mahou-shoujo/'),
  Genre(name: 'Mecha', link: MECHA),
  Genre(name: 'Music', link: MUSIC),
  Genre(name: 'Mystery', link: MYSTERY),
  Genre(name: 'Psychological', link: PSYCHOLOGICAL),
  Genre(name: 'Romance', link: ROMANCE),
  Genre(name: 'Sci-Fi', link: SCI_FI),
  Genre(name: 'Slice of Life', link: SLICE_OF_LIFE),
  Genre(name: 'Sports', link: SPORTS),
  Genre(name: 'Supernatural', link: SUPER_NATURAL),
  Genre(name: 'Thriller', link: THRILLER),
];
