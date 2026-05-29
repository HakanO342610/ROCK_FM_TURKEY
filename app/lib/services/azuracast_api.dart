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

  /// Bir dosyayı kuyruğa zorla ekle (en üstte sıraya girer).
  Future<void> queueRequest(int mediaId) async {
    await _postJson('/station/$stationId/queue/$mediaId', {});
  }

  /// Kuyruğa zorla eklenmiş bir kaydı sil.
  Future<void> removeFromQueue(int queueId) async {
    await _delete('/station/$stationId/queue/$queueId');
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

  /// Bir mp3 dosyasını yükle. AzuraCast multipart yerine base64-encoded JSON kabul ediyor.
  Future<Map<String, dynamic>> uploadFile({
    required String path,
    required List<int> bytes,
  }) async {
    final body = {
      'path': path,
      'file': base64Encode(bytes),
    };
    final j = await _postJson('/station/$stationId/files', body);
    return Map<String, dynamic>.from(j as Map);
  }

  /// Multipart upload (alternatif — büyük dosyalar için daha verimli).
  Future<Map<String, dynamic>> uploadFileMultipart({
    required File file,
    required String relativePath,
  }) async {
    final uri = _u('/station/$stationId/files');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers);
    req.fields['path'] = relativePath;
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    _check(resp);
    return Map<String, dynamic>.from(jsonDecode(resp.body) as Map);
  }
}
