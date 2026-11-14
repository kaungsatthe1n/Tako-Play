/// Returns a readable language label for a subtitle track when its metadata or
/// URL makes the language identifiable.
///
/// All URL parsing is guarded: subtitle filenames and signed query strings are
/// external input and must never interrupt stream resolution.
String subtitleDisplayName(
  String? suppliedName,
  String subtitleUrl, {
  int fallbackIndex = 1,
}) {
  final supplied = suppliedName?.trim();
  if (supplied != null && supplied.isNotEmpty && !_isGenericLabel(supplied)) {
    return _languageName(supplied) ?? supplied;
  }

  try {
    final uri = Uri.tryParse(subtitleUrl);
    if (uri != null) {
      for (final entry in uri.query.split('&')) {
        final separator = entry.indexOf('=');
        if (separator < 0) continue;
        final key = _safeDecode(entry.substring(0, separator))
            .replaceAll('+', ' ')
            .toLowerCase();
        if (!const {
          'lang',
          'language',
          'locale',
          'srclang',
          'label',
          'name',
        }.contains(key)) {
          continue;
        }
        final value =
            _safeDecode(entry.substring(separator + 1)).replaceAll('+', ' ');
        final language = _languageName(value);
        if (language != null) return language;
      }

      final segments = uri.pathSegments.reversed;
      for (final segment in segments) {
        final decoded = _safeDecode(segment);
        final stem = decoded.replaceFirst(
          RegExp(r'\.(vtt|srt|ttml)$', caseSensitive: false),
          '',
        );
        final wholeName = _languageName(stem);
        if (wholeName != null) return wholeName;
        final tokens = stem.split(RegExp(r'[^A-Za-z0-9]+'));
        for (final token in tokens.reversed) {
          final language = _languageName(token);
          if (language != null) return language;
        }
      }
    }
  } catch (_) {
    // Malformed provider URLs should only fall back to the generic label.
  }
  return 'Subtitle $fallbackIndex';
}

bool _isGenericLabel(String value) =>
    const {'subtitles', 'subtitle', 'subs', 'unknown'}.contains(
      value.trim().toLowerCase(),
    ) ||
    RegExp(r'^subtitle\s*\d+$', caseSensitive: false).hasMatch(value.trim());

bool isEnglishSubtitleName(String value) =>
    _languageName(value) == 'English' ||
    RegExp(r'^(en|eng|english)(?:[-_\s]|$)', caseSensitive: false)
        .hasMatch(value.trim());

String _safeDecode(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

String? _languageName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('_', '-');
  final firstPart = normalized.split('-').first;
  const names = <String, String>{
    'ar': 'Arabic',
    'ara': 'Arabic',
    'arabic': 'Arabic',
    'de': 'German',
    'deu': 'German',
    'ger': 'German',
    'german': 'German',
    'en': 'English',
    'eng': 'English',
    'english': 'English',
    'es': 'Spanish',
    'spa': 'Spanish',
    'spanish': 'Spanish',
    'fil': 'Filipino',
    'filipino': 'Filipino',
    'tl': 'Filipino',
    'tagalog': 'Filipino',
    'fr': 'French',
    'fra': 'French',
    'fre': 'French',
    'french': 'French',
    'hi': 'Hindi',
    'hin': 'Hindi',
    'hindi': 'Hindi',
    'id': 'Indonesian',
    'ind': 'Indonesian',
    'indonesian': 'Indonesian',
    'it': 'Italian',
    'ita': 'Italian',
    'italian': 'Italian',
    'ja': 'Japanese',
    'jpn': 'Japanese',
    'japanese': 'Japanese',
    'ko': 'Korean',
    'kor': 'Korean',
    'korean': 'Korean',
    'ms': 'Malay',
    'msa': 'Malay',
    'may': 'Malay',
    'malay': 'Malay',
    'nl': 'Dutch',
    'nld': 'Dutch',
    'dut': 'Dutch',
    'dutch': 'Dutch',
    'pt': 'Portuguese',
    'por': 'Portuguese',
    'portuguese': 'Portuguese',
    'ru': 'Russian',
    'rus': 'Russian',
    'russian': 'Russian',
    'th': 'Thai',
    'tha': 'Thai',
    'thai': 'Thai',
    'tr': 'Turkish',
    'tur': 'Turkish',
    'turkish': 'Turkish',
    'vi': 'Vietnamese',
    'vie': 'Vietnamese',
    'vietnamese': 'Vietnamese',
    'zh': 'Chinese',
    'zho': 'Chinese',
    'chi': 'Chinese',
    'chinese': 'Chinese',
  };
  return names[normalized] ?? names[firstPart];
}
