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

  static final List<FeedItem> itensMock = [
    FeedItem(
      id: 1,
      titulo: 'Cadeira de Madeira Maciça',
      fotos: const [],
      status: 'ANUNCIADO',
      categoria: 'MÓVEIS',
      descricao:
          'Linda cadeira em carvalho claro, ideal para escritório ou sala de jantar. Muito bem conservada e sem arranhões.',
      doadorNome: 'Ricardo Santos',
      localizacao: 'Curitiba',
      criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
      estadoConservacao: 'usado',
    ),
    FeedItem(
      id: 2,
      titulo: 'Coleção Literatura Clássica',
      fotos: const [],
      status: 'ANUNCIADO',
      categoria: 'LIVROS',
      descricao:
          'Conjunto de 5 livros clássicos em ótimo estado. Perfeitos para colecionadores ou estudantes de literatura.',
      doadorNome: 'Ana Oliveira',
      localizacao: 'Londrina',
      criadoEm: DateTime.now().subtract(const Duration(hours: 5)),
      estadoConservacao: 'novo',
    ),
    FeedItem(
      id: 3,
      titulo: 'Luminária Vintage Industrial',
      fotos: const [],
      status: 'ANUNCIADO',
      categoria: 'ELETRÔNICOS',
      descricao:
          'Luminária de mesa em latão e ferro. Funciona perfeitamente e acompanha lâmpada de filamento.',
      doadorNome: 'Marcos Paulo',
      localizacao: 'Curitiba',
      criadoEm: DateTime.now().subtract(const Duration(days: 1)),
      estadoConservacao: 'usado',
    ),
    FeedItem(
      id: 4,
      titulo: 'Jogo de Jantar Cerâmica',
      fotos: const [],
      status: 'ANUNCIADO',
      categoria: 'UTENSÍLIOS',
      descricao:
          'Conjunto completo para 4 pessoas. Cerâmica artesanal em tom areia, sem lascas ou trincas.',
      doadorNome: 'Julia Mendes',
      localizacao: 'Toledo',
      criadoEm: DateTime.now().subtract(const Duration(hours: 3)),
      estadoConservacao: 'novo',
    ),
    FeedItem(
      id: 5,
      titulo: 'Smartwatch 1ª Geração',
      fotos: const [],
      status: 'ANUNCIADO',
      categoria: 'ELETRÔNICOS',
      descricao:
          'Relógio inteligente em perfeito estado. Acompanha carregador original e pulseira extra.',
      doadorNome: 'Lucas Weber',
      localizacao: 'Curitiba',
      criadoEm: DateTime.now().subtract(const Duration(hours: 6)),
      estadoConservacao: 'precisa_de_reparo',
    ),
    FeedItem(
      id: 6,
      titulo: 'Kit Camisetas Algodão',
      fotos: const [],
      status: 'ANUNCIADO',
      categoria: 'ROUPAS',
      descricao:
          '4 camisetas básicas de algodão orgânico, tamanho G. Cores neutras e tecido de alta qualidade.',
      doadorNome: 'Beatriz Lima',
      localizacao: 'Ponta Grossa',
      criadoEm: DateTime.now().subtract(const Duration(hours: 8)),
      estadoConservacao: 'usado',
    ),
  ];
}
