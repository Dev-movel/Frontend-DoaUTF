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

Future<List<dynamic>> buscarUsuarios() async {
    try {
      String? token;
      try {
        token = await TokenStorage.instance.getAccessToken();
      } catch (e) {
        debugPrint('Erro ao ler token no storage: $e');
      }

      final response = await _dio.get(
        '/usuarios',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.data is List) {
        return response.data as List<dynamic>;
      } else {
        return response.data['usuarios'] ?? []; 
      }

    } on DioException catch (e) {
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Mensagem: ${e.message}');
      debugPrint('Erro Dio: ${e.response?.data}');
      throw Exception('Erro ao carregar usuários.');
    } catch (e) {
      debugPrint('Erro inesperado no buscarUsuarios: $e');
      throw Exception('Erro inesperado ao buscar usuários.');
    }
  }

  Future<Map<String, dynamic>> atualizarUsuario({
    required int id,
    String? nome,
    String? email,
    String? senha,
    String? dataNascimento,
    bool? bloqueado,
  }) async {
    try {
      final token = await TokenStorage.instance.getAccessToken();

      final Map<String, dynamic> body = {};
      
      if (nome != null && nome.isNotEmpty) body['nome'] = nome;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (senha != null && senha.isNotEmpty) body['senha'] = senha;
      if (dataNascimento != null && dataNascimento.isNotEmpty) body['data_nascimento'] = dataNascimento;
      if (bloqueado != null) body['bloqueado'] = bloqueado;

      final response = await _dio.patch(
        '/usuarios/$id',
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['erro'] ?? 'Dados inválidos.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Usuário não encontrado.');
      }
      throw Exception('Erro interno ao atualizar usuário.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
