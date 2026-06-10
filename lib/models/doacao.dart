class AgendamentoResumo {
  final int id;
  final String status;
  final DateTime? dataHora;

  AgendamentoResumo({
    required this.id,
    required this.status,
    this.dataHora,
  });

  factory AgendamentoResumo.fromJson(Map<String, dynamic> json) {
    return AgendamentoResumo(
      id: json['id'],
      status: json['status'] ?? 'pendente',
      dataHora: json['data_hora'] != null ? DateTime.tryParse(json['data_hora']) : null,
    );
  }
}

class Doacao {
  final int id;
  final String titulo;
  final String? fotoUrl;
  final String status;

  final int quantidadeSolicitacoesPendentes;
  final AgendamentoResumo? agendamentoAtivo;

  static const String _backendBaseUrl = 'http://localhost:3000';

  Doacao({
    required this.id,
    required this.titulo,
    this.fotoUrl,
    required this.status,
    this.quantidadeSolicitacoesPendentes = 0,
    this.agendamentoAtivo,
  });

  factory Doacao.fromJson(Map<String, dynamic> json) {
    final rawFotoUrl = json['foto_url'] as String?;
    return Doacao(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sem título',
      fotoUrl: _normalizeFotoUrl(rawFotoUrl),
      status: json['status'] ?? 'DESCONHECIDO',
      quantidadeSolicitacoesPendentes: json['quantidade_solicitacoes_pendentes'] ?? 0,
      agendamentoAtivo: json['agendamento_ativo'] != null
          ? AgendamentoResumo.fromJson(json['agendamento_ativo'])
          : null,
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