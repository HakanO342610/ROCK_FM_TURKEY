class NowPlaying {
  final String title;
  final String artist;
  final String? art;
  final NowPlaying? playingNext;
  final List<NowPlaying> history;

  const NowPlaying({
    required this.title,
    required this.artist,
    this.art,
    this.playingNext,
    this.history = const [],
  });

  factory NowPlaying.fromJson(Map<String, dynamic> json) {
    final song = json['song'] as Map<String, dynamic>? ?? const {};
    return NowPlaying(
      title: (song['title'] as String?)?.trim().isNotEmpty == true
          ? song['title'] as String
          : 'Canlı Yayın',
      artist: (song['artist'] as String?)?.trim().isNotEmpty == true
          ? song['artist'] as String
          : 'RockFM Turkey',
      art: song['art'] as String?,
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
      playingNext: next,
      history: history,
    );
  }
}
