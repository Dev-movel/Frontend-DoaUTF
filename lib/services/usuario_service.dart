import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/doacao.dart';
import '../auth/services/token_storage.dart';

class UsuarioService {
  UsuarioService._();
  static final UsuarioService instance = UsuarioService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Options> _getAuthOptions() async {
    final token = await TokenStorage.instance.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Usuario> getMe() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/usuarios/me', options: options);

      debugPrint('✅ [GET /usuarios/me] Dados recebidos: ${response.data}');

      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [GET /usuarios/me] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar dados do usuário.');
    }
  }

  Future<void> updateMe(Map<String, dynamic> dados) async {
    try {
      final options = await _getAuthOptions();
      await _dio.patch(
        '/usuarios/me',
        data: dados,
        options: options,
      );
      debugPrint('✅ [PATCH /usuarios/me] Perfil atualizado com sucesso!');
    } on DioException catch (e) {
      debugPrint('❌ [PATCH /usuarios/me] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao atualizar perfil.');
    }
  }

  Future<List<Doacao>> getMyDonations() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/usuarios/me/donations', options: options);

      debugPrint('✅ [GET /usuarios/me/donations] Doações recebidas: ${response.data}');

      // Se a resposta vier paginada (ex: { "data": [...] }), mude para response.data['data']
      final List<dynamic> data = response.data is Map ? response.data['data'] : response.data;
      
      return data.map((json) => Doacao.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /usuarios/me/donations] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar doações.');
    }
  }

  String? _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response?.data['erro'];
    }
    return null;
  }
}