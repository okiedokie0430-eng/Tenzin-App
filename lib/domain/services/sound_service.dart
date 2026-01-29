import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Dedicated low-latency player for short UI sounds
  final AudioPlayer _effectPlayer = AudioPlayer(playerId: 'effect_player');

  // Preloaded bytes for quick playback
  Uint8List? _completedBytes;
  Uint8List? _correctBytes;
  Uint8List? _wrongBytes;

  bool _initialized = false;

  /// Call once at app startup (or will auto-init on first play)
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _effectPlayer.setPlayerMode(PlayerMode.lowLatency);
      try {
        await _effectPlayer.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
    } catch (_) {
      // ignore if API doesn't support setting mode
    }
    try {
      final a = await rootBundle.load('assets/sounds/completed.wav');
      _completedBytes = a.buffer.asUint8List();
    } catch (_) {
      _completedBytes = null;
    }
    try {
      final a = await rootBundle.load('assets/sounds/correct.mp3');
      _correctBytes = a.buffer.asUint8List();
    } catch (_) {
      _correctBytes = null;
    }
    try {
      final a = await rootBundle.load('assets/sounds/wrong.mp3');
      _wrongBytes = a.buffer.asUint8List();
    } catch (_) {
      _wrongBytes = null;
    }
    _initialized = true;
  }

  Future<void> playCorrectSound() async {
    if (!_initialized) await init();
    try {
      if (_correctBytes != null) {
        await _effectPlayer.play(BytesSource(_correctBytes!));
        return;
      }
      await _effectPlayer.play(AssetSource('assets/sounds/correct.mp3'));
    } catch (e) {
      try {
        final fallback = AudioPlayer();
        await fallback.play(AssetSource('assetssounds/correct.mp3'));
        await fallback.dispose();
      } catch (_) {
        // final fallback ignored
      }
    }
  }

  Future<void> playWrongSound() async {
    if (!_initialized) await init();
    try {
      if (_wrongBytes != null) {
        await _effectPlayer.play(BytesSource(_wrongBytes!));
        return;
      }
      await _effectPlayer.play(AssetSource('assets/sounds/wrong.mp3'));
    } catch (e) {
      try {
        final fallback = AudioPlayer();
        await fallback.play(AssetSource('assets/sounds/wrong.mp3'));
        await fallback.dispose();
      } catch (_) {}
    }
  }

  Future<void> playCompletedSound() async {
    if (!_initialized) await init();
    try {
      if (_completedBytes != null) {
        await _effectPlayer.play(BytesSource(_completedBytes!));
        return;
      }
      await _effectPlayer.play(AssetSource('assets/sounds/completed.wav'));
    } catch (e) {
      try {
        final fallback = AudioPlayer();
        await fallback.play(AssetSource('assets/sounds/completed.wav'));
        await fallback.dispose();
      } catch (_) {}
    }
  }

  void dispose() {
    _effectPlayer.dispose();
  }
}
