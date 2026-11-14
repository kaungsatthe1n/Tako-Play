import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/playback_context.dart';
import '../services/ending_timing_service.dart';
import '../services/playback_service.dart';

/// Owns next-episode timing and one speculative request, without a second player.
class NextEpisodeController extends ChangeNotifier {
  NextEpisodeController({
    required PlaybackContext? context,
    required this.loadSource,
    required this.findEnding,
    required this.playSource,
    this.skipOpening,
    Duration? endingStart,
    SkipInterval? opening,
    DateTime Function()? now,
  })  : _context = context,
        _endingStart = endingStart,
        _opening = opening,
        _now = now ?? DateTime.now;

  final Future<PlaybackSource> Function(PlaybackContext) loadSource;
  final Future<Duration?> Function(PlaybackContext, Duration) findEnding;
  final Future<void> Function(PlaybackContext, PlaybackSource) playSource;
  final Future<void> Function(Duration end)? skipOpening;
  final DateTime Function() _now;
  PlaybackContext? _context;
  Duration? _endingStart;
  SkipInterval? _opening;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _timingRequested = false;
  bool _prefetchAttempted = false;
  bool _suppressAutoPrefetch = false;
  bool _dismissed = false;
  bool _disposed = false;
  int _generation = 0;
  int _timingGeneration = 0;
  PlaybackSource? _prepared;
  DateTime? _preparedAt;
  Future<PlaybackSource?>? _pending;
  bool isSwitching = false;
  bool isPreparing = false;
  bool hasError = false;
  bool _openingSkipped = false;

  PlaybackContext? get context => _context;
  void attachContext(PlaybackContext context) {
    if (_disposed || _context != null) return;
    _context = context;
    _requestEndingTiming();
    _maybePrefetch();
    notifyListeners();
  }

  PlaybackContext? get next => _context?.next;
  bool get isReady => _prepared != null;
  bool get hasEndingTiming =>
      _endingStart != null &&
      _endingStart! >= _duration ~/ 2 &&
      _endingStart! < _duration;
  Duration get promptAt => hasEndingTiming
      ? _endingStart!
      : (_duration > const Duration(seconds: 30)
          ? _duration - const Duration(seconds: 30)
          : _duration);
  bool get isVisible =>
      next != null &&
      !_dismissed &&
      _duration > Duration.zero &&
      _position >= promptAt;
  bool get isOpeningVisible =>
      !_openingSkipped &&
      _opening != null &&
      _position >= _opening!.start &&
      _position <= _opening!.end;

  void updateProgress(Duration position, Duration duration) {
    if (_disposed || isSwitching || duration <= Duration.zero) {
      return;
    }
    final wasVisible = isVisible;
    final wasOpeningVisible = isOpeningVisible;
    _position = position;
    _duration = duration;
    _requestEndingTiming();
    if (_context != null) _maybePrefetch();
    if (wasVisible != isVisible || wasOpeningVisible != isOpeningVisible) {
      notifyListeners();
    }
  }

  void _requestEndingTiming() {
    if (_context == null || _timingRequested || _duration <= Duration.zero) {
      return;
    }
    _timingRequested = true;
    final generation = _timingGeneration;
    if (next != null && !hasEndingTiming) {
      unawaited(_lookupEnding(generation));
    }
  }

  Future<void> skipOpeningNow() async {
    final opening = _opening;
    final seek = skipOpening;
    if (_disposed || !isOpeningVisible || opening == null || seek == null) {
      return;
    }
    try {
      await seek(opening.end);
      if (_disposed) return;
      _openingSkipped = true;
      notifyListeners();
    } catch (_) {
      // Leave the button available if the seek fails.
    }
  }

  /// Seeking close to the end should never spin up a hidden player and steal
  /// resources/audio focus from the video the user is actively watching.
  /// The explicit Play next action can still load the episode on demand.
  void onSeek() {
    if (_disposed) return;
    _suppressAutoPrefetch = true;
    _generation++;
    _pending = null;
    _prefetchAttempted = false;
    _prepared = null;
    _preparedAt = null;
    isPreparing = false;
    hasError = false;
    notifyListeners();
  }

  Future<void> _lookupEnding(int generation) async {
    try {
      final ending = await findEnding(_context!, _duration);
      if (_disposed || generation != _timingGeneration) return;
      if (ending != null) _endingStart = ending;
      _maybePrefetch();
      notifyListeners();
    } catch (_) {/* Keep the duration-based prompt. */}
  }

  void _maybePrefetch() {
    if (!_prefetchAttempted &&
        !_suppressAutoPrefetch &&
        !_dismissed &&
        _position >= promptAt - const Duration(seconds: 60)) {
      _prefetchAttempted = true;
      unawaited(_prepare());
    }
  }

  Future<PlaybackSource?> _prepare() {
    if (_pending != null) return _pending!;
    final target = next;
    if (_disposed || target == null) return Future.value();
    isPreparing = true;
    hasError = false;
    final generation = _generation;
    notifyListeners();
    final pending = () async {
      try {
        final source = await Future.sync(() => loadSource(target));
        if (_disposed || generation != _generation) return null;
        _prepared = source;
        _preparedAt = _now();
        return source;
      } catch (_) {
        if (!_disposed && generation == _generation) hasError = true;
        return null;
      } finally {
        if (!_disposed && generation == _generation) {
          _pending = null;
          isPreparing = false;
          notifyListeners();
        }
      }
    }();
    _pending = pending;
    return pending;
  }

  void dismiss() {
    if (_disposed || isSwitching) return;
    _dismissed = true;
    notifyListeners();
  }

  Future<void> playNext() async {
    final target = next;
    if (_disposed || target == null || isSwitching) return;
    isSwitching = true;
    hasError = false;
    notifyListeners();
    try {
      // Signed links are short lived. Resolve again after a long pause/seek.
      var source = _preparedAt != null &&
              _now().difference(_preparedAt!) < const Duration(minutes: 2)
          ? _prepared
          : null;
      source ??= await _prepare();
      if (_disposed || source == null) return;
      await playSource(target, source);
      if (_disposed) return;
      _generation++;
      _timingGeneration++;
      _context = target;
      _endingStart = source.endingStart;
      _opening = source.opening;
      _openingSkipped = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _timingRequested = false;
      _prefetchAttempted = false;
      _suppressAutoPrefetch = false;
      _dismissed = false;
      _prepared = null;
      _preparedAt = null;
      hasError = false;
    } catch (_) {
      _prepared = null;
      _preparedAt = null;
      hasError = true;
    } finally {
      if (!_disposed) {
        isSwitching = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timingGeneration++;
    super.dispose();
  }
}
