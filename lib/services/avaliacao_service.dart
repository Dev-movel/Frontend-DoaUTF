import 'package:dio/dio.dart';
import '../auth/services/api_client.dart';

class AvaliacaoService {
  AvaliacaoService._();
  static final AvaliacaoService instance = AvaliacaoService._();

  Dio get _dio => ApiClient.instance;

  /// Envia uma avaliação para um item entregue.
  ///
  /// [itemId]: ID do item doado
  /// [nota]: Inteiro de 1 a 5
  /// [comentario]: Opcional, máx 500 caracteres
  ///
  /// Retorna um Map com os dados da avaliação criada.
  /// Exceções:
  /// - DioException (status 403): item não entregue
  /// - DioException (status 409): já avaliou este item
  /// - DioException (status 410): prazo de 7 dias expirou
  /// - DioException (status 422): nota/comentário inválido
  Future<Map<String, dynamic>> enviarAvaliacao({
    required int itemId,
    required int nota,
    String? comentario,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/avaliacao/donations/$itemId/review',
      data: {
        'nota': nota,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario.trim(),
      },
    );

    return response.data!;
  }

  /// Lista avaliações recebidas por um usuário específico.
  ///
  /// [usuarioId]: ID do usuário cujas avaliações queremos ver
  /// [page]: Página (default: 1)
  /// [limit]: Itens por página (default: 10, máx: 100)
  ///
  /// Retorna um Map contendo:
  /// - avaliacoes: List<Map> com cada avaliação
  /// - reputacao: Map com total_avaliacoes, media_avaliacoes, etc.
  /// - paginacao: Map com page, limit, total, totalPages
  Future<Map<String, dynamic>> getAvaliacoesDoUsuario(
    int usuarioId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/avaliacao/users/$usuarioId/reviews',
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.data!;
  }

  /// Obtém a reputação (média de estrelas) do usuário logado.
  ///
  /// Retorna um Map com:
  /// - total_avaliacoes: int
  /// - media_avaliacoes: double (ou null se nenhuma avaliação)
  /// - cinco_estrelas: int
  /// - quatro_ou_mais_estrelas: int
  Future<Map<String, dynamic>> minhaReputacao() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/avaliacao/users/me/reputacao',
    );

    return response.data!;
  }

  /// Denuncia uma avaliação como inapropriada.
  ///
  /// [avaliacaoId]: ID da avaliação
  /// [motivo]: Motivo da denúncia (opcional, máx 255 chars)
  Future<Map<String, dynamic>> denunciarAvaliacao(
    int avaliacaoId, {
    String? motivo,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/avaliacao/reviews/$avaliacaoId/report',
      data: {
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo.trim(),
      },
    );

    return response.data!;
  }
}