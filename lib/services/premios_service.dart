import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/services/token_storage.dart';
import '../config/app_config.dart';
import '../models/resgate.dart';

class PremiosService {
  PremiosService._();
  static final PremiosService instance = PremiosService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<Options> _auth() async {
    final token = await TokenStorage.instance.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// GET /pontos/saldo → { saldo: 150 }
  Future<int> buscarSaldo() async {
    try {
      final r = await _dio.get('/pontos/saldo', options: await _auth());
      return int.tryParse('${r.data['saldo'] ?? 0}') ?? 0;
    } on DioException catch (e) {
      debugPrint('❌ [GET /pontos/saldo] ${e.response?.statusCode}');
      return 0;
    }
  }

  /// POST /pontos/resgatar → { premio_id, premio_nome, pontos_gastos, codigo, saldo_restante }
  Future<Map<String, dynamic>> resgatar(int premioId) async {
    final r = await _dio.post(
      '/pontos/resgatar',
      data: {'premio_id': premioId},
      options: await _auth(),
    );
    return r.data as Map<String, dynamic>;
  }

  /// GET /pontos/resgates → lista de resgates do usuário
  Future<List<Resgate>> buscarResgates() async {
    try {
      final r = await _dio.get('/pontos/resgates', options: await _auth());
      final list = r.data as List<dynamic>;
      return list
          .map((e) => Resgate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET /pontos/resgates] ${e.response?.statusCode}');
      return [];
    }
  }
}
