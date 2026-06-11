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

  Future<void> denunciarUsuario(int usuarioId) async {
    try {
      final options = await _getAuthOptions();
      
      await _dio.patch(
        '/usuarios/$usuarioId/denunciar',
        options: options,
      );

      debugPrint('[PATCH /usuarios/$usuarioId/denunciar] Denúncia feita com sucesso!');
    } on DioException catch (e) {
      debugPrint('[PATCH /usuarios/$usuarioId/denunciar] Erro: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('Usuário não encontrado.');
      }
      
      throw Exception(_extractError(e) ?? 'Falha ao processar denúncia. Tente novamente mais tarde.');
    } catch (e) {
      throw Exception('Erro inesperado ao tentar denunciar: $e');
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

  Future<List<Doacao>> getMyDonations({String? status}) async {
    try {
      final options = await _getAuthOptions();
      
      final Map<String, dynamic> queryParams = {};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/usuarios/me/donations',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: options,
      );

      debugPrint('✅ [GET /usuarios/me/donations] Doações feitas: ${response.data}');

      final List<dynamic> data = response.data is Map ? response.data['data'] : response.data;      

      return data.map((json) => Doacao.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /usuarios/me/donations] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar doações.');
    }
  }

  Future<List<Doacao>> getReceivedDonations() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/usuarios/me/received', options: options);

      debugPrint('✅ [GET /usuarios/me/received] Doações recebidas: ${response.data}');

      final List<dynamic> data = response.data is Map ? response.data['data'] : response.data;
      return data.map((json) => Doacao.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /usuarios/me/received] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar doações recebidas.');
    }
  }

  Future<List<dynamic>> getMyAgendamentos() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/usuarios/me/agendamentos', options: options);

      debugPrint('✅ [GET /usuarios/me/agendamentos] Agendamentos: ${response.data}');

      final raw = response.data is Map ? response.data['data'] : response.data;
      if (raw is List) return raw;
      if (raw == null) return <dynamic>[];
      return [raw];
    } on DioException catch (e) {
      debugPrint('❌ [GET /usuarios/me/agendamentos] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar agendamentos.');
    }
  }
  Future<Usuario> getUsuarioById(int id) async {
    try {
      // rota pública que retorna todos os usuários; filtrar localmente pelo id
      final response = await _dio.get('/usuarios');
      final list = response.data is List ? response.data as List<dynamic> : (response.data['usuarios'] ?? []);
      final found = list.cast<Map<String, dynamic>>().firstWhere((u) => (u['id']?.toString() ?? '') == id.toString(), orElse: () => {});
      if (found.isEmpty) throw Exception('Usuário não encontrado');
      debugPrint('[GET /usuarios] Usuário carregado: ${found}');
      return Usuario.fromJson(found);
    } on DioException catch (e) {
      debugPrint('[GET /usuarios] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar usuário.');
    }
  }
  String? _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response?.data['erro'];
    }
    return null;
  }
}