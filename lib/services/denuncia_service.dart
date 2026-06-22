import 'package:dio/dio.dart';
import 'package:doaai/auth/services/token_storage.dart';

class DenunciaService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000')); 

  static final DenunciaService instance = DenunciaService._();
  DenunciaService._();

  Future<void> enviarDenuncia({
    required String itemId,
    required String motivo,
    required String descricao,
  }) async {
    try {
      final String? token = await TokenStorage.instance.getAccessToken();

      final response = await _dio.post(
        '/usuarios/denunciar-post',
        data: {
          'itemId': itemId,
          'motivo': motivo,
          'descricao': descricao,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 201) {
        final data = response.data;
        if (data is Map && data.containsKey('erro')) {
          throw Exception(data['erro']);
        }
        throw Exception('Erro desconhecido ao denunciar. Status: ${response.statusCode}');
      }

    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        
        if (data is Map && data.containsKey('erro')) {
          throw Exception(data['erro']);
        }
        
        throw Exception('Erro do servidor: $data');
      }
      throw Exception('Falha de conexão com a API.');
    } catch (e) {
      throw Exception('Erro ao processar a denúncia: $e');
    }
  }
}