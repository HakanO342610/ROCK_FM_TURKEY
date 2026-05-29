import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/now_playing.dart';
import 'history_service.dart';
import 'player_service.dart';

class NowPlayingService extends ChangeNotifier {
  final HistoryService history;
  NowPlaying? _current;
  Timer? _timer;
  bool _loading = false;

  NowPlayingService({required this.history});

  NowPlaying? get current => _current;
  bool get loading => _loading;

  void start() {
    if (_timer != null) return;
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetch());
  }

  Future<void> _fetch() async {
    if (_loading) return;
    _loading = true;
    try {
      final res = await http
          .get(Uri.parse(PlayerService.nowPlayingUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          _current = NowPlaying.fromApiRoot(body);
          notifyListeners();
          await history.recordIfChanged(_current!);
        }
      }
    } catch (e) {
      debugPrint('NowPlaying fetch error: $e');
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
