class NowPlaying {
  final String title;
  final String artist;
  final String? art;
  final int? duration; // seconds
  final NowPlaying? playingNext;
  final List<NowPlaying> history;

  const NowPlaying({
    required this.title,
    required this.artist,
    this.art,
    this.duration,
    this.playingNext,
    this.history = const [],
  });

  String? get durationFormatted {
    if (duration == null || duration! <= 0) return null;
    final m = duration! ~/ 60;
    final s = duration! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory NowPlaying.fromJson(Map<String, dynamic> json) {
    final song = json['song'] as Map<String, dynamic>? ?? const {};
    final rawDuration = json['duration'];
    return NowPlaying(
      title: (song['title'] as String?)?.trim().isNotEmpty == true
          ? song['title'] as String
          : 'Canlı Yayın',
      artist: (song['artist'] as String?)?.trim().isNotEmpty == true
          ? song['artist'] as String
          : 'RockFM Turkey',
      art: song['art'] as String?,
      duration: rawDuration is int
          ? rawDuration
          : rawDuration is double
              ? rawDuration.toInt()
              : null,
    );
  }

  static NowPlaying fromApiRoot(Map<String, dynamic> root) {
    final now = NowPlaying.fromJson(
      (root['now_playing'] as Map<String, dynamic>?) ?? const {},
    );
    final next = root['playing_next'] != null
        ? NowPlaying.fromJson(root['playing_next'] as Map<String, dynamic>)
        : null;
    final history = ((root['song_history'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NowPlaying.fromJson)
        .toList();
    return NowPlaying(
      title: now.title,
      artist: now.artist,
      art: now.art,
      duration: now.duration,
      playingNext: next,
      history: history,
    );
  }
}
