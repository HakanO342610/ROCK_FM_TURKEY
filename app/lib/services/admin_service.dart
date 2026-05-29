import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Admin oturumunu API key bazlı yönetir.
/// Abdullah Abi AzuraCast web admin'inde profile > API Keys'ten kendi key'ini
/// oluşturur, mobile login ekranına bir kere yapıştırır. Bundan sonra
/// secure storage'da saklanır ve tüm admin çağrılarında X-API-Key olarak gider.
class AdminService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _kKey = 'azuracast_api_key';

  String? _apiKey;
  String? get apiKey => _apiKey;
  bool get isLoggedIn => _apiKey != null && _apiKey!.isNotEmpty;

  Future<void> load() async {
    _apiKey = await _storage.read(key: _kKey);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    await _storage.write(key: _kKey, value: trimmed);
    _apiKey = trimmed;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: _kKey);
    _apiKey = null;
    notifyListeners();
  }
}
