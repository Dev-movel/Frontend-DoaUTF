import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/feed_item.dart';

class FeedService {
  FeedService._();
  static final FeedService instance = FeedService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<List<FeedItem>> buscarItens({
    String? categoria,
    String? busca,
    int pagina = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/itens',
        queryParameters: {
          if (categoria != null) 'categoria': categoria,
          if (busca != null && busca.isNotEmpty) 'busca': busca,
          'pagina': pagina,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /itens] ${e.response?.statusCode} – ${e.response?.data}');
      throw Exception(_extractError(e) ?? 'Erro ao buscar doações.');
    }
  }

  String? _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response?.data['erro'] ?? e.response?.data['message'];
    }
    return null;
  }

}
