import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/now_playing.dart';

class TrackEntry {
  final int? id;
  final String title;
  final String artist;
  final String? art;
  final DateTime playedAt;
  final bool favorite;

  const TrackEntry({
    this.id,
    required this.title,
    required this.artist,
    this.art,
    required this.playedAt,
    this.favorite = false,
  });

  Map<String, Object?> toMap() => {
        'title': title,
        'artist': artist,
        'art': art,
        'played_at': playedAt.millisecondsSinceEpoch,
        'favorite': favorite ? 1 : 0,
      };

  factory TrackEntry.fromMap(Map<String, Object?> m) => TrackEntry(
        id: m['id'] as int?,
        title: m['title'] as String,
        artist: m['artist'] as String,
        art: m['art'] as String?,
        playedAt: DateTime.fromMillisecondsSinceEpoch(m['played_at'] as int),
        favorite: (m['favorite'] as int? ?? 0) == 1,
      );

  String get key => '$artist::$title';
}

class HistoryService extends ChangeNotifier {
  Database? _db;
  List<TrackEntry> _history = [];
  List<TrackEntry> _favorites = [];
  String? _lastKey;

  List<TrackEntry> get history => _history;
  List<TrackEntry> get favorites => _favorites;

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      '${dir.path}/rockfm.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            art TEXT,
            played_at INTEGER NOT NULL,
            favorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_played_at ON tracks(played_at DESC)');
        await db.execute('CREATE INDEX idx_favorite ON tracks(favorite)');
      },
    );
    await _refresh();
  }

  Future<void> recordIfChanged(NowPlaying np) async {
    if (_db == null) return;
    final key = '${np.artist}::${np.title}';
    if (key == _lastKey) return;
    if (np.title == 'Canlı Yayın') return;
    _lastKey = key;
    await _db!.insert('tracks', TrackEntry(
      title: np.title,
      artist: np.artist,
      art: np.art,
      playedAt: DateTime.now(),
    ).toMap());
    await _refresh();
  }

  Future<void> toggleFavorite(TrackEntry t) async {
    if (_db == null || t.id == null) return;
    await _db!.update(
      'tracks',
      {'favorite': t.favorite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [t.id],
    );
    await _refresh();
  }

  Future<void> clearHistory() async {
    if (_db == null) return;
    await _db!.delete('tracks', where: 'favorite = 0');
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_db == null) return;
    final h = await _db!.query('tracks',
        orderBy: 'played_at DESC', limit: 100);
    final f = await _db!.query('tracks',
        where: 'favorite = 1', orderBy: 'played_at DESC');
    _history = h.map(TrackEntry.fromMap).toList();
    _favorites = f.map(TrackEntry.fromMap).toList();
    notifyListeners();
  }
}
