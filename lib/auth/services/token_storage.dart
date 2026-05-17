import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccess  = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyIsAdmin = 'is_admin';

  // Cache em memória para evitar latência do FlutterSecureStorage na primeira escrita
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  Future<String?> getAccessToken() async =>
      _cachedAccessToken ?? await _storage.read(key: _keyAccess);

  Future<String?> getRefreshToken() async =>
      _cachedRefreshToken ?? await _storage.read(key: _keyRefresh);

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccessToken  = accessToken;
    _cachedRefreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _keyAccess,  value: accessToken),
      _storage.write(key: _keyRefresh, value: refreshToken),
    ]);
  }

  Future<void> updateAccessToken(String accessToken) {
    _cachedAccessToken = accessToken;
    return _storage.write(key: _keyAccess, value: accessToken);
  }

  Future<void> clearTokens() async {
    _cachedAccessToken  = null;
    _cachedRefreshToken = null;
    await Future.wait([
      _storage.delete(key: _keyAccess),
      _storage.delete(key: _keyRefresh),
      _storage.delete(key: _keyIsAdmin),
    ]);
  }

  Future<void> saveIsAdmin(bool isAdmin) async {
    await _storage.write(key: _keyIsAdmin, value: isAdmin.toString());
  }

  Future<bool> getIsAdmin() async {
    final value = await _storage.read(key: _keyIsAdmin);
    return value == 'true';
  }
}