import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    webOptions: WebOptions(
      dbName: 'doautf_auth', 
      publicKey: 'auth_key_static',
    ),
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
    _memIsAdmin = isAdmin;
    try {
      await _storage.write(key: _keyIsAdmin, value: isAdmin.toString());
    } catch (e) {}
  }

  Future<void> clearTokens() async {
    _memAccess = null;
    _memRefresh = null;
    _memIsAdmin = null;

    try {
      await Future.wait([
        _storage.delete(key: _keyAccess),
        _storage.delete(key: _keyRefresh),
        _storage.delete(key: _keyIsAdmin), 
      ]);
    } catch (e) {
      debugPrint('Aviso Storage Web: Erro ao limpar disco.');
    }
  }
}