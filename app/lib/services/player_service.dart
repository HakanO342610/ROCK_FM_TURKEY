import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class PlayerService extends ChangeNotifier {
  static const String streamUrl =
      'https://stream.rockfmturkey.com/listen/rockfmturkey/radio.mp3';
  static const String nowPlayingUrl =
      'https://rockfmturkey.com/api/nowplaying/1';

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _lastError;

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  String? get lastError => _lastError;

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    if (_initialized) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // iOS'ta MediaItem tag'i ile kilit ekran kontrolleri çalışır
      // (JustAudioBackground.init main.dart'ta iOS için çağrılıyor).
      // Android'de tag'siz plain AudioSource (just_audio_background beta
      // _audioHandler LateInitError veriyor — sonra stable paket eklenecek).
      final source = AudioSource.uri(
        Uri.parse(streamUrl),
        tag: Platform.isIOS
            ? MediaItem(
                id: 'rockfm-live',
                album: 'RockFM Turkey',
                title: 'Canlı Yayın',
                artist: '7/24 Rock',
              )
            : null,
      );
      await _player.setAudioSource(source, preload: false);

      _player.playerStateStream.listen((_) => notifyListeners());
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          _lastError = e.toString();
          debugPrint('AudioPlayer ERROR: $e\n$st');
          notifyListeners();
        },
      );

      _initialized = true;
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('PlayerService.init FAILED: $e\n$st');
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> toggle() async {
    try {
      _lastError = null;
      if (!_initialized) {
        await init();
      }
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('PlayerService.toggle ERROR: $e\n$st');
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
