import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:uuid/uuid.dart';
import '../models/anime.dart';
import '../services/request_service.dart';
import '../utils/constants.dart';

class AnimeService {
  Future<AnimeResults> getSearchResult(String title) async {
    List<Anime> _animeList = [];
    final response = await RequestService.create().requestSearchResponse(title);
    dom.Document document = parse(response.body);
    var list = document
        .getElementsByClassName('video_player followed  default')
        .first
        .getElementsByClassName('listing items')
        .first
        .getElementsByTagName('li');

    for (var element in list) {
      var info = element.getElementsByTagName('a').first;
      var href = info.attributes.values.first;
      var url = info
          .getElementsByTagName('div')
          .first
          .getElementsByClassName('picture')
          .first
          .getElementsByTagName('img')
          .first
          .attributes
          .values;

      Anime animeInfo =
          Anime(name: url.last, imageUrl: url.first, episodeUrl: href);
      _animeList.add(animeInfo);
    }
    return AnimeResults(animeList: _animeList);
  }

  Future<AnimeResults> fetchEpisodes(String path) async {
    List<Anime> _animeList = [];
    final response = await RequestService.create().requestEpisodeResponse(path);
    dom.Document document = parse(response.body);
    var list = document
        .getElementsByClassName('listing items lists')
        .first
        .getElementsByTagName('li');

    for (var element in list) {
      var url = element.getElementsByTagName('a').first.attributes.values.first;
      var ep = element
          .getElementsByTagName('a')
          .first
          .getElementsByClassName('name')
          .first
          .text
          .trim();

      Anime animeInfo = Anime(
        episodeUrl: url,
      );
      _animeList.add(animeInfo);
    }
    return AnimeResults(animeList: _animeList.reversed.toList());
  }

  Future<String> fetchIframeEmbedded(path) async {
    final response = await RequestService.create().requestEpisodeResponse(path);
    dom.Document document = parse(response.body);
    var embededIframeUrl = document
        .getElementsByClassName('play-video')
        .first
        .getElementsByTagName('iframe')
        .first
        .attributes
        .values
        .first;
    // print("IFrame : $embededIframeUrl ");
    return embededIframeUrl;
  }

  Future<String> fetchTokenEmbedded(url) async {
    final response = await RequestService.create().requestEmbededResponse(url);
    dom.Document document = parse(response.body);
    var tokenEmbeddedUrl = document
        .getElementById('list-server-more')!
        .children[1]
        .children[1]
        .attributes
        .values
        .last;
    // print("Token : $tokenEmbeddedUrl ");
    return tokenEmbeddedUrl;
  }

  Future<String> fetchActualVideo(url) async {
    var response =
        await RequestService.create().requestActualVideoResponse(url);
    dom.Document docu = parse(response.body);
    var info = docu.getElementsByClassName('videocontent').first.text;
    var videoFile = mediaFileRegExp.firstMatch(info)!.group(0).toString();
    // print("videoFile : $videoFile ");
    return videoFile;
  }

  Future<String> getVideoUrl(path) async {
    var iframeEmbedded = await fetchIframeEmbedded(path);
    var tokenEmbedded = await fetchTokenEmbedded(iframeEmbedded);
    var actualUrl = await fetchActualVideo(tokenEmbedded);
    // print("ActualUrl : $actualUrl ");
    return actualUrl;
  }

  Future<AnimeResults> getAnimes(request) async {
    List<Anime> _animeList = [];

    final response = await request;
    dom.Document document = parse(response.body);
    var list = document
        .getElementsByClassName('listing items')
        .first
        .getElementsByClassName('video-block');

    for (var element in list) {
      var episode = element
          .getElementsByTagName('a')
          .first
          .getElementsByClassName('name')
          .first
          .text
          .toString()
          .trim();

      var info = element
          .getElementsByTagName('a')
          .first
          .getElementsByClassName('img')
          .first
          .getElementsByClassName('picture')
          .first
          .getElementsByTagName('img')
          .first
          .attributes
          .values;

      var href =
          element.getElementsByTagName('a').first.attributes.values.first;

      var img = info.first;
      var title = info.last;
      var uuid = const Uuid();

      Anime animeInfo = Anime(
        id: uuid.v4(),
        name: title,
        imageUrl: img,
        episodeUrl: href,
        currentEp: episode,
      );
      _animeList.add(animeInfo);
    }
    return AnimeResults(animeList: _animeList);
  }
}
