import 'package:flutter_test/flutter_test.dart';
import 'package:tako_play/utils/subtitle_name.dart';

void main() {
  test('infers subtitle languages from labels, query and filename', () {
    expect(
        subtitleDisplayName('en-US', 'https://example.com/a.vtt'), 'English');
    expect(subtitleDisplayName('Director notes', 'https://example.com/a.vtt'),
        'Director notes');
    expect(subtitleDisplayName(null, 'https://example.com/a.vtt?x=1&lang=ja'),
        'Japanese');
    expect(subtitleDisplayName('Subtitle 1', 'https://example.com/en.vtt'),
        'English');
    expect(subtitleDisplayName(null, 'https://example.com/movie.fr.srt'),
        'French');
    expect(
        subtitleDisplayName(null, 'https://example.com/movie.vtt',
            fallbackIndex: 3),
        'Subtitle 3');
    expect(isEnglishSubtitleName('English CC'), isTrue);
    expect(isEnglishSubtitleName('French'), isFalse);
    expect(subtitleDisplayName(null, 'https://example.com/a.vtt?lang=%FF'),
        'Subtitle 1');
  });
}
