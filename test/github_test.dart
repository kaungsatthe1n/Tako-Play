import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/models/github.dart';

void main() {
  test('recognizes an APK by asset name without a file extension in the URL',
      () {
    final release = Github.fromJson({
      'assets': [
        {
          'name': 'release.apk',
          'browser_download_url': 'https://example.com/download'
        }
      ],
    });
    expect(release.apkDownloadLink, 'https://example.com/download');
  });
  test('reads the first usable release asset', () {
    final release = Github.fromJson({
      'tag_name': ' v1.7.0 ',
      'body': ' Improvements ',
      'assets': [
        {'browser_download_url': ''},
        {'browser_download_url': 'https://example.com/tako.apk'},
      ],
    });

    expect(release.version, 'v1.7.0');
    expect(release.newFeatures, 'Improvements');
    expect(release.downloadLink, 'https://example.com/tako.apk');
  });

  test('accepts a release without downloadable assets', () {
    final release = Github.fromJson({
      'tag_name': 'v1.7.0',
      'assets': <Object>[],
    });

    expect(release.downloadLink, isNull);
  });
}
