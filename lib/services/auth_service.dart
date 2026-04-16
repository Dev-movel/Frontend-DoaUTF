import 'dart:convert';
import 'package:http/http.dart' as http;

// Altere para o endereço do seu backend
const _baseUrl = 'http://localhost:6125';

class AuthService {
  /// Cadastra um novo usuário. Lança [Exception] em caso de erro.
  static Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
    String? dataNascimento, // formato esperado pelo back: yyyy-MM-dd
  }) async {
    final body = {
      'nome': nome,
      'email': email,
      'senha': senha,
      if (dataNascimento != null && dataNascimento.isNotEmpty)
        'data_nascimento': dataNascimento,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 400) {
      final msg = _parseErrorMessage(response.body);
      throw Exception(msg ?? 'E-mail inválido ou já cadastrado.');
    }

    throw Exception('Erro interno. Tente novamente mais tarde.');
  }

  static String? _parseErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
