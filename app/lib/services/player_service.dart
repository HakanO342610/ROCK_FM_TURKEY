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

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;

  Future<void> init() async {
    if (_initialized) return;
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: 'rockfm-live',
          album: 'RockFM Turkey',
          title: 'Canlı Yayın',
          artist: '7/24 Rock',
        ),
      ),
    );
    _player.playerStateStream.listen((_) => notifyListeners());
    _initialized = true;
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
