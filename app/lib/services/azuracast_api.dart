import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AzuraCastException implements Exception {
  final int status;
  final String message;
  AzuraCastException(this.status, this.message);
  @override
  String toString() => 'AzuraCastException($status): $message';
}

/// AzuraCast REST API'sine X-API-Key auth ile çağrı atan thin client.
/// Tek istasyon (id=1) varsayımıyla tasarlanmıştır — sonradan istasyon
/// genişletmesi gerekirse stationId parametresi alır.
class AzuraCastApi {
  static const String baseUrl = 'https://rockfmturkey.com/api';
  static const int stationId = 1;

  final String apiKey;
  AzuraCastApi(this.apiKey);

  Map<String, String> get _headers => {
        'X-API-Key': apiKey,
        'Accept': 'application/json',
      };

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> _get(String path) async {
    final r = await http.get(_u(path), headers: _headers);
    _check(r);
    return jsonDecode(r.body);
  }

  Future<dynamic> _delete(String path) async {
    final r = await http.delete(_u(path), headers: _headers);
    _check(r);
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  Future<dynamic> _postJson(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      _u(path),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _check(r);
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  Future<dynamic> _putJson(String path, Object body) async {
    final r = await http.put(
      _u(path),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _check(r);
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String msg = r.body;
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['message'] is String) msg = j['message'];
    } catch (_) {}
    throw AzuraCastException(r.statusCode, msg);
  }

  /// API key'in geçerli olup olmadığını test eder (mevcut hesap bilgilerini çeker).
  Future<Map<String, dynamic>> verifyApiKey() async {
    final j = await _get('/frontend/account/me');
    return Map<String, dynamic>.from(j as Map);
  }

  /// Şu an çalan + yakın kuyruk bilgisi (public endpoint, key olmadan da çalışır).
  Future<Map<String, dynamic>> nowPlaying() async {
    final r = await http.get(_u('/nowplaying/$stationId'));
    _check(r);
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  /// Yaklaşan kuyrukta bekleyen şarkılar.
  Future<List<Map<String, dynamic>>> queue() async {
    final j = await _get('/station/$stationId/queue');
    return (j as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// İstasyondaki tüm medya dosyaları (kütüphane).
  Future<List<Map<String, dynamic>>> files({String? search}) async {
    final qp = search == null || search.isEmpty
        ? ''
        : '?searchPhrase=${Uri.encodeQueryComponent(search)}';
    final j = await _get('/station/$stationId/files/list$qp');
    return (j as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Kuyruktaki bir kaydı sil (otomatik playlist'in oluşturduğu sırayı temizlemek için).
  Future<void> removeFromQueue(int queueId) async {
    await _delete('/station/$stationId/queue/$queueId');
  }

  /// Yayını şu an çalan şarkıdan bir sonrakine atla.
  /// AzuraCast Liquidsoap backend'ine skip komutu gönderir.
  Future<void> skipCurrentSong() async {
    await _postJson('/station/$stationId/backend/skip', {});
  }

  // ─── Playlists ───────────────────────────────────────────────────────────

  /// İstasyonun tüm playlist'lerini listele.
  Future<List<Map<String, dynamic>>> playlists() async {
    final j = await _get('/station/$stationId/playlists');
    return (j as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Yeni playlist oluştur. type: 'default' (sıralı kuyruk) | 'once_per_x_songs' | 'once_per_x_minutes' | 'once_per_hour' | 'advanced'
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String type = 'default',
    String source = 'songs',
    String order = 'sequential',
  }) async {
    final j = await _postJson('/station/$stationId/playlists', {
      'name': name,
      'type': type,
      'source': source,
      'order': order,
      'is_enabled': true,
    });
    return Map<String, dynamic>.from(j as Map);
  }

  /// Playlist'i aktif/pasif yap (toggle).
  Future<void> togglePlaylist(int playlistId) async {
    await _putJson('/station/$stationId/playlist/$playlistId/toggle', {});
  }

  /// Playlist'i sil.
  Future<void> deletePlaylist(int playlistId) async {
    await _delete('/station/$stationId/playlist/$playlistId');
  }

  /// Playlist'in sıralı şarkı sırasını getir (media id listesi).
  Future<List<Map<String, dynamic>>> playlistOrder(int playlistId) async {
    final j = await _get('/station/$stationId/playlist/$playlistId/order');
    if (j is List) {
      return j.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  /// Playlist'in sıralı şarkı sırasını kaydet.
  Future<void> setPlaylistOrder(int playlistId, List<int> orderedMediaIds) async {
    await _putJson(
      '/station/$stationId/playlist/$playlistId/order',
      orderedMediaIds,
    );
  }

  /// Karıştırılmış playlist için yeniden karıştır.
  Future<void> reshufflePlaylist(int playlistId) async {
    await _putJson('/station/$stationId/playlist/$playlistId/reshuffle', {});
  }

  // ─── Media ↔ Playlist atama ─────────────────────────────────────────────

  /// Tek bir dosyanın detayını getir (şu anda hangi playlist'lerde olduğunu görmek için).
  Future<Map<String, dynamic>> getFile(int mediaId) async {
    final j = await _get('/station/$stationId/file/$mediaId');
    return Map<String, dynamic>.from(j as Map);
  }

  /// Bir medya dosyasının playlist atamalarını güncelle.
  /// playlistIds: dosyanın ait olacağı playlist ID'lerinin tam listesi.
  Future<void> setFilePlaylists(int mediaId, List<int> playlistIds) async {
    final current = await getFile(mediaId);
    current['playlists'] = playlistIds.map((id) => {'id': id}).toList();
    await _putJson('/station/$stationId/file/$mediaId', current);
  }

  /// Kütüphaneden dosya sil.
  Future<void> deleteFile(int mediaId) async {
    await _delete('/station/$stationId/file/$mediaId');
  }

  /// Aktif dinleyici listesi (anlık).
  Future<List<Map<String, dynamic>>> listeners() async {
    final j = await _get('/station/$stationId/listeners');
    return (j as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Bir mp3 dosyasını yükle ve istenirse default playlist'e otomatik ata.
  /// AzuraCast `/files/upload` endpoint'i Flow.js multipart protokolü bekliyor.
  /// `/files` endpoint'i internal bug veriyor ("storage_location_id not initialized").
  Future<Map<String, dynamic>> uploadFile({
    required String filename,
    required File file,
    bool assignToDefaultPlaylist = true,
  }) async {
    final size = await file.length();
    final identifier = '${DateTime.now().millisecondsSinceEpoch}-$filename';
    final uri = _u('/station/$stationId/files/upload');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers);
    req.fields['flowFilename'] = filename;
    req.fields['flowChunkNumber'] = '1';
    req.fields['flowTotalChunks'] = '1';
    req.fields['flowIdentifier'] = identifier;
    req.fields['flowChunkSize'] = size.toString();
    req.fields['flowTotalSize'] = size.toString();
    req.fields['flowCurrentChunkSize'] = size.toString();
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    _check(resp);
    final result = resp.body.isEmpty
        ? {'success': true}
        : Map<String, dynamic>.from(jsonDecode(resp.body) as Map);

    // AzuraCast upload sonrası ID döndürmüyor — yüklenen dosyayı path ile bul,
    // ardından default (ilk aktif) playlist'e ata. Hatası uploadu fail etmez.
    if (assignToDefaultPlaylist) {
      try {
        await _autoAssignToDefaultPlaylist(filename);
      } catch (e) {
        // sessiz fail — dosya yüklendi, playlist atama best-effort
      }
    }
    return result;
  }

  Future<void> _autoAssignToDefaultPlaylist(String filename) async {
    final plId = await getDefaultPlaylistId();
    if (plId == null) return;

    // Yeni yüklenen dosyanın path'ini bul
    final files = await this.files(search: filename);
    final match = files.firstWhere(
      (f) {
        final p = (f['path'] ?? '').toString();
        return p == filename || p.endsWith('/$filename');
      },
      orElse: () => const {},
    );
    final path = match['path'];
    if (path is! String || path.isEmpty) return;

    await addFilesToPlaylist([path], plId);
  }

  /// İlk aktif playlist'in ID'sini (yoksa ilk playlist'in) döndürür.
  Future<int?> getDefaultPlaylistId() async {
    final pls = await playlists();
    final defaultPl = pls.firstWhere(
      (p) => p['is_enabled'] == true,
      orElse: () => pls.isNotEmpty ? pls.first : const {},
    );
    final plId = defaultPl['id'];
    return plId is int ? plId : null;
  }

  /// Bir veya daha fazla dosyayı (path ile) verilen playlist'e ekle.
  /// AzuraCast batch endpoint kullanır — per-file PUT broken olduğu için tek yol bu.
  Future<void> addFilesToPlaylist(List<String> paths, int playlistId) async {
    if (paths.isEmpty) return;
    await _putJson('/station/$stationId/files/batch', {
      'do': 'playlist',
      'files': paths,
      'dirs': <String>[],
      'playlists': [playlistId],
    });
  }
}
