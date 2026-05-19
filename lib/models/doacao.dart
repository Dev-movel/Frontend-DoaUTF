class Doacao {
  final int id;
  final String titulo;
  final String? fotoUrl;
  final String status;

  static const String _backendBaseUrl = 'http://localhost:3000';

  Doacao({
    required this.id,
    required this.titulo,
    this.fotoUrl,
    required this.status,
  });

  factory Doacao.fromJson(Map<String, dynamic> json) {
    final rawFotoUrl = json['foto_url'] as String?;
    return Doacao(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sem título',
      fotoUrl: _normalizeFotoUrl(rawFotoUrl),
      status: json['status'] ?? 'DESCONHECIDO',
    );
  }

  static String? _normalizeFotoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$_backendBaseUrl$trimmed';
    }
    return '$_backendBaseUrl/$trimmed';
  }
}