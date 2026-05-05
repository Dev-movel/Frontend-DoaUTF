import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/token_storage.dart';
import '../models/doacao_form.dart';

class CategoriaItem {
  final int id;
  final String nome;
  const CategoriaItem({required this.id, required this.nome});
}

class DoacaoService {
  DoacaoService._();
  static final DoacaoService instance = DoacaoService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Options> _getAuthOptions() async {
    final token = await TokenStorage.instance.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<CategoriaItem>> buscarCategorias() async {
    try {
      final options  = await _getAuthOptions();
      final response = await _dio.get('/categorias', options: options);
      final list     = response.data as List<dynamic>;
      return list
          .map((e) => CategoriaItem(
                id:   e['id']   as int,
                nome: e['nome'] as String,
              ))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /categorias] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar categorias.');
    }
  }

  Future<void> publicar(DoacaoForm form) async {
    try {
      final options  = await _getAuthOptions();
      final formData = await _buildFormData(form);
      await _dio.post('/itens', data: formData, options: options);
      debugPrint('✅ [POST /itens] Item cadastrado com sucesso!');
    } on DioException catch (e) {
      debugPrint('❌ [POST /itens] Erro: ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao publicar doação.');
    }
  }

  Future<void> salvarRascunho(DoacaoForm form) async {
    throw Exception('Rascunho não suportado pelo servidor no momento.');
  }

  Future<FormData> _buildFormData(DoacaoForm form) async {
    final fields = <String, dynamic>{
      'titulo'            : form.titulo,
      'descricao'         : form.descricao,
      'categoria_id'      : form.categoriaId,
      'estado_conservacao': _mapEstado(form.estadoConservacao),
      'local_retirada'    : form.localRetirada,
    };

    final List<MultipartFile> imagens = [];
    for (final xfile in form.fotos) {
      imagens.add(await MultipartFile.fromFile(
        xfile.path,
        filename: xfile.name,
      ));
    }

    return FormData.fromMap({
      ...fields,
      if (imagens.isNotEmpty) 'imagens': imagens,
    });
  }

  String _mapEstado(String label) => switch (label) {
    'Novo'              => 'novo',
    'Usado'             => 'usado',
    'Precisa de reparo' => 'precisa_de_reparo',
    _                   => label.toLowerCase(),
  };

  String? _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response?.data['erro'] ?? e.response?.data['message'];
    }
    return null;
  }
}