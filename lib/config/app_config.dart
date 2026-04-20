/// Configuração do app para desenvolvimento/produção
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String appVersion = '1.0.0';
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);
}
