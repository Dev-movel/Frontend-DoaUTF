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

  String? _cachedAccess;
  String? _cachedRefresh;
  bool? _cachedIsAdmin;

  Future<String?> getAccessToken() async {
    if (_cachedAccess != null) return _cachedAccess;
    try {
      _cachedAccess = await _storage.read(key: _keyAccess);
      return _cachedAccess;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefresh != null) return _cachedRefresh;
    try {
      _cachedRefresh = await _storage.read(key: _keyRefresh);
      return _cachedRefresh;
    } catch (e) {
      return null;
    }
  }

  Future<bool> getIsAdmin() async {
    if (_cachedIsAdmin != null) return _cachedIsAdmin!;
    try {
      final value = await _storage.read(key: _keyIsAdmin);
      _cachedIsAdmin = value == 'true';
      return _cachedIsAdmin!;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _cachedAccess  = accessToken;
    _cachedRefresh = refreshToken;
    
    try {
      await Future.wait([
        _storage.write(key: _keyAccess,  value: accessToken),
        _storage.write(key: _keyRefresh, value: refreshToken),
      ]);
    } catch (e) {
      debugPrint('Aviso Storage Web: Não salvou no disco, mas está na memória.');
    }
  }

  Future<void> updateAccessToken(String accessToken) async {
    _cachedAccess = accessToken;
    try {
      await _storage.write(key: _keyAccess, value: accessToken);
    } catch (e) {}
  }

  Future<void> saveIsAdmin(bool isAdmin) async {
    _cachedIsAdmin = isAdmin;
    try {
      await _storage.write(key: _keyIsAdmin, value: isAdmin.toString());
    } catch (e) {}
  }

  Future<void> clearTokens() async {
    _cachedAccess  = null;
    _cachedRefresh = null;
    _cachedIsAdmin = null;

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