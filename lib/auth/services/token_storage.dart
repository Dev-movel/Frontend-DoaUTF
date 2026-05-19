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

  String? _memAccess;
  String? _memRefresh;
  bool? _memIsAdmin;

  Future<String?> getAccessToken() async {
    if (_memAccess != null) return _memAccess;
    try {
      _memAccess = await _storage.read(key: _keyAccess);
      return _memAccess;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_memRefresh != null) return _memRefresh;
    try {
      _memRefresh = await _storage.read(key: _keyRefresh);
      return _memRefresh;
    } catch (e) {
      return null;
    }
  }

  Future<bool> getIsAdmin() async {
    if (_memIsAdmin != null) return _memIsAdmin!;
    try {
      final value = await _storage.read(key: _keyIsAdmin);
      _memIsAdmin = value == 'true';
      return _memIsAdmin!;
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
    _memAccess = accessToken;
    _memRefresh = refreshToken;

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
    _memAccess = accessToken;
    try {
      await _storage.write(key: _keyAccess, value: accessToken);
    } catch (e) {}
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