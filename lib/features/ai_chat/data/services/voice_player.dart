import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;

/// Neutral playback status, shared by every [VoicePlayer] backend so the UI
/// does not depend on a specific audio engine.
enum VoicePlayerStatus { playing, paused, stopped, completed }

/// A thin voice-message player abstraction.
///
/// Android (and every non-iOS platform) uses `audioplayers`, which already
/// works there. iOS uses `media_kit` (libmpv) because AVFoundation — the
/// engine behind `audioplayers` on iOS — cannot decode the Opus/OGG/WebM
/// voice files the backend sends. media_kit is only instantiated on iOS, so
/// no libmpv binaries are pulled into the Android build.
abstract class VoicePlayer {
  factory VoicePlayer() =>
      Platform.isIOS ? _MediaKitVoicePlayer() : _AudioPlayersVoicePlayer();

  Stream<VoicePlayerStatus> get statusStream;
  Stream<Duration> get durationStream;
  Stream<Duration> get positionStream;

  /// Plays a local file at [path], replacing anything currently playing.
  Future<void> playFile(String path);

  /// Plays a remote [url], replacing anything currently playing.
  Future<void> playUrl(String url);

  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class _AudioPlayersVoicePlayer implements VoicePlayer {
  final ap.AudioPlayer _player = ap.AudioPlayer();

  @override
  Stream<VoicePlayerStatus> get statusStream =>
      _player.onPlayerStateChanged.map(_mapState);

  @override
  Stream<Duration> get durationStream => _player.onDurationChanged;

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;

  VoicePlayerStatus _mapState(ap.PlayerState state) {
    switch (state) {
      case ap.PlayerState.playing:
        return VoicePlayerStatus.playing;
      case ap.PlayerState.paused:
        return VoicePlayerStatus.paused;
      case ap.PlayerState.completed:
        return VoicePlayerStatus.completed;
      case ap.PlayerState.stopped:
      case ap.PlayerState.disposed:
        return VoicePlayerStatus.stopped;
    }
  }

  @override
  Future<void> playFile(String path) => _player.play(ap.DeviceFileSource(path));

  @override
  Future<void> playUrl(String url) => _player.play(ap.UrlSource(url));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class _MediaKitVoicePlayer implements VoicePlayer {
  _MediaKitVoicePlayer() {
    // MediaKit.ensureInitialized() MUST run before the Player is constructed.
    // `_player` is a lazy `late final` field, so it is built on first access
    // below — after this call — not in a field initializer that would run
    // before the constructor body and throw.
    _ensureInitialized();
    _playingSub = _player.stream.playing.listen((playing) {
      _status.add(
        playing ? VoicePlayerStatus.playing : VoicePlayerStatus.paused,
      );
    });
    _completedSub = _player.stream.completed.listen((completed) {
      if (completed) {
        _status.add(VoicePlayerStatus.completed);
      }
    });
    _errorSub = _player.stream.error.listen((error) {
      debugPrint('🎙️ media_kit voice error: $error');
    });
  }

  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) {
      return;
    }
    mk.MediaKit.ensureInitialized();
    _initialized = true;
  }

  late final mk.Player _player = mk.Player();
  final StreamController<VoicePlayerStatus> _status =
      StreamController<VoicePlayerStatus>.broadcast();
  late final StreamSubscription<bool> _playingSub;
  late final StreamSubscription<bool> _completedSub;
  late final StreamSubscription<String> _errorSub;

  @override
  Stream<VoicePlayerStatus> get statusStream => _status.stream;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Future<void> playFile(String path) => _player.open(mk.Media(path));

  @override
  Future<void> playUrl(String url) => _player.open(mk.Media(url));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _playingSub.cancel();
    await _completedSub.cancel();
    await _errorSub.cancel();
    await _status.close();
    await _player.dispose();
  }
}
