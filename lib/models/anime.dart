import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class AnimeResults {
  AnimeResults({
    required this.animeList,
  });

  final List<Anime>? animeList;
}

class Anime {
  Anime({
    this.id,
    this.name,
    this.imageUrl,
    this.status,
    this.summary,
    this.genres,
    this.episodes,
    this.currentEp,
    this.animeUrl,
    this.releasedDate,
  });

  final String? id;
  final String? name;
  final String? imageUrl;
  final String? summary;
  final String? status;
  final String? animeUrl;
  final List<Genre>? genres;
  final List<Episode>? episodes;
  final String? currentEp;
  final String? releasedDate;
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
  Genre(
    name: 'Action',
    link: ACTION,
  ),
  Genre(
    name: 'Adventure',
    link: ADVENTURE,
  ),
  Genre(
    name: 'Cars',
    link: CARS,
  ),
  Genre(
    name: 'Comedy',
    link: COMEDY,
  ),
  Genre(
    name: 'Crime',
    link: CRIME,
  ),
  Genre(
    name: 'Dementai',
    link: DEMENTIA,
  ),
  Genre(
    name: 'Demons',
    link: DEMONS,
  ),
  Genre(
    name: 'Drama',
    link: DRAMA,
  ),
  Genre(
    name: 'Dub',
    link: DUB,
  ),
  Genre(
    name: 'Ecchi',
    link: ECCHI,
  ),
  Genre(
    name: 'Family',
    link: FAMILY,
  ),
  Genre(
    name: 'Fantasy',
    link: FANTASY,
  ),
  Genre(
    name: 'Game',
    link: GAME,
  ),
  Genre(
    name: 'Harem',
    link: HAREM,
  ),
  Genre(
    name: 'Historical',
    link: HISTORICAL,
  ),
  Genre(
    name: 'Horror',
    link: HORROR,
  ),
  Genre(
    name: 'Josei',
    link: JOSEI,
  ),
  Genre(
    name: 'Kids',
    link: KIDS,
  ),
  Genre(
    name: 'Magic',
    link: MAGIC,
  ),
  Genre(
    name: 'Mecha',
    link: MECHA,
  ),
  Genre(
    name: 'Military',
    link: MILITARY,
  ),
  Genre(
    name: 'Music',
    link: MUSIC,
  ),
  Genre(
    name: 'Mystery',
    link: MYSTERY,
  ),
  Genre(
    name: 'Parody',
    link: PARODY,
  ),
  Genre(
    name: 'Police',
    link: POLICE,
  ),
  Genre(
    name: 'Psychological',
    link: PSYCHOLOGICAL,
  ),
  Genre(
    name: 'Romance',
    link: ROMANCE,
  ),
  Genre(
    name: 'Samurai',
    link: SAMURAI,
  ),
  Genre(
    name: 'School',
    link: SCHOOL,
  ),
  Genre(
    name: 'Sci-Fi',
    link: SCI_FI,
  ),
  Genre(
    name: 'Seinen',
    link: SEINEN,
  ),
  Genre(
    name: 'Shoujo',
    link: SHOUJO,
  ),
  Genre(
    name: 'Shoujo Ai',
    link: SHOUJO_AI,
  ),
  Genre(
    name: 'Shounen',
    link: SHOUNEN,
  ),
  Genre(
    name: 'Shounen Ai',
    link: SHOUNEN_AI,
  ),
  Genre(
    name: 'Slice Of Life',
    link: SLICE_OF_LIFE,
  ),
  Genre(
    name: 'Space',
    link: SPACE,
  ),
  Genre(
    name: 'Sports',
    link: SPORTS,
  ),
  Genre(
    name: 'Super Power',
    link: SUPER_POWER,
  ),
  Genre(
    name: 'Supernatural',
    link: SUPER_NATURAL,
  ),
  Genre(
    name: 'Suspense',
    link: SUSPENSE,
  ),
  Genre(
    name: 'Thriller',
    link: THRILLER,
  ),
  Genre(
    name: 'Vampire',
    link: VAMPIRE,
  ),
  Genre(
    name: 'Yaoi',
    link: YAOI,
  ),
  Genre(
    name: 'Yuri',
    link: YURI,
  ),
];
