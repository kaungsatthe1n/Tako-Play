import 'package:chopper/chopper.dart';

import '../utils/constants.dart';

part 'request_service.chopper.dart';

/// [RequestService] is a data source consuming remote APIs for fetching and
/// managing data about the actual anime. The implementation of those requests
/// can be found in the auto-generated file `request_service.chopper.dart` , since any changes will be overridden after
/// running the build command.
@ChopperApi(baseUrl: baseUrl)
abstract class RequestService extends ChopperService {
  Future<Response> requestRecentlyAddedResponse();

  @Get(path: '$search{title}')
  Future<Response> requestSearchResponse(@Path('title') String name);

  @Get(path: '{path}')
  Future<Response> requestAnimeDetailResponse(@Path('path') String path);

  @Get(path: 'popular.html')
  Future<Response> requestPopularResponse();

  @Get(path: 'anime-movies.html')
  Future<Response> requestMoviesResponse();

  Future<Response> requestAnimeGenre(String url,[int index]);

  Future<Response> requestEpisodesResponse(String id);

  Future<Response> requestGitHubUpdate(String url);

  Future<Response> requestCdnVideoLink(String url);

  static RequestService create() {
    final client = ChopperClient(
        interceptors: [HttpLoggingInterceptor()],
        services: [_$RequestService()]);
    return _$RequestService(client);
  }
}
