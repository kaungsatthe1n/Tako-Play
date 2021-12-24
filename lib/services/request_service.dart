import 'package:chopper/chopper.dart';
import '../utils/constants.dart';
part 'request_service.chopper.dart';

@ChopperApi(baseUrl: baseUrl)
abstract class RequestService extends ChopperService {
  @Get()
  Future<Response> fetchHomePage();

  @Get(path: '$search{title}')
  Future<Response> requestSearchResponse(@Path('title') String name);

  @Get(path: '{path}')
  Future<Response> requestEpisodeResponse(@Path('path') String path);

  @Get(path: 'popular')
  Future<Response> requestPopularResponse();

  @Get(path: 'ongoing-series')
  Future<Response> requestOnGoingResponse();

  Future<Response> requestGitHubUpdate(String url);

  static RequestService create() {
    final client = ChopperClient(
        interceptors: [HttpLoggingInterceptor()],
        services: [_$RequestService()]);
    return _$RequestService(client);
  }
}
