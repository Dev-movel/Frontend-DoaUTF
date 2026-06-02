import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  Future<Options> _getAuthOptions() async {
    final token = await TokenStorage.instance.getAccessToken();
    
    if (token == null || token.isEmpty) {
      debugPrint('🚨 [AdminService] Abortando requisição: Nenhum token encontrado no Storage!');
      throw Exception('Usuário não autenticado.');
    }
    
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  String? _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response?.data['erro'] ?? e.response?.data['message'];
    }
    return null;
  }
  Future<List<dynamic>> buscarUsuarios({bool apenasDenunciados = false}) async {
    try {
      final options = await _getAuthOptions();

      final response = await _dio.get(
        '/usuarios',
        queryParameters: {
          if (apenasDenunciados) 'apenasDenunciados': 'true',
        },
        options: options,
      );

      if (response.data is List) {
        return response.data as List<dynamic>;
      } else {
        return response.data['usuarios'] ?? []; 
      }

    } on DioException catch (e) {
      debugPrint('❌ [GET /usuarios] Status Code: ${e.response?.statusCode}');
      debugPrint('Erro Dio: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao carregar usuários.');
    } catch (e) {
      debugPrint('❌ Erro inesperado no buscarUsuarios: $e');
      throw Exception('Erro inesperado ao buscar usuários.');
    }
  }

  Future<void> atualizarUsuario({required int id, bool? bloqueado, bool? denunciado}) async {
    try {
      final options = await _getAuthOptions();
      final data = <String, dynamic>{};
      
      if (bloqueado != null) data['bloqueado'] = bloqueado;
      if (denunciado != null) data['denunciado'] = denunciado;

      await _dio.patch(
        '/usuarios/$id', 
        data: data, 
        options: options,
      );
      debugPrint('✅ [PATCH /admin/usuarios/$id] Usuário atualizado.');
    } on DioException catch (e) {
      debugPrint('❌ Erro ao atualizar usuário: ${e.response?.data}');
      throw Exception('Falha ao atualizar o status do usuário.');
    }
  }

  Future<List<dynamic>> buscarDoacoesAtivas() async {
    try {
      final options = await _getAuthOptions(); 
      final response = await _dio.get('/itens/ativos', options: options);
      
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
      return [];
    } on DioException catch (e) {
      debugPrint('⚠️ [GET /itens/ativos] Falhou (${e.response?.statusCode}). Verifique se a rota existe no Node.');
      return []; 
    } catch (e) {
      debugPrint('❌ Erro inesperado em buscarDoacoesAtivas: $e');
      return [];
    }
  }
}