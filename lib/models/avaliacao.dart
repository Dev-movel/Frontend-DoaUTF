class AvaliacaoRecebida {
  final int id;
  final int nota;
  final String? comentario;
  final DateTime createdAt;
  final int avaliadorId;
  final String avaliadorNome;
  final int itemId;
  final String itemTitulo;

  const AvaliacaoRecebida({
    required this.id,
    required this.nota,
    this.comentario,
    required this.createdAt,
    required this.avaliadorId,
    required this.avaliadorNome,
    required this.itemId,
    required this.itemTitulo,
  });

  factory AvaliacaoRecebida.fromJson(Map<String, dynamic> json) {
    return AvaliacaoRecebida(
      id:            json['id'] as int,
      nota:          json['nota'] as int,
      comentario:    json['comentario'] as String?,
      createdAt:     DateTime.parse(json['created_at'] as String).toLocal(),
      avaliadorId:   json['avaliador_id'] as int,
      avaliadorNome: json['avaliador_nome'] as String,
      itemId:        json['item_id'] as int,
      itemTitulo:    json['item_titulo'] as String,
    );
  }
}

class Reputacao {
  final int totalAvaliacoes;
  final double? mediaAvaliacoes;
  final int cincoEstrelas;
  final int quatroOuMaisEstrelas;

  const Reputacao({
    required this.totalAvaliacoes,
    this.mediaAvaliacoes,
    required this.cincoEstrelas,
    required this.quatroOuMaisEstrelas,
  });

  factory Reputacao.fromJson(Map<String, dynamic> json) {
    return Reputacao(
      totalAvaliacoes:        json['total_avaliacoes'] as int? ?? 0,
      mediaAvaliacoes:        json['media_avaliacoes'] as double?,
      cincoEstrelas:          json['cinco_estrelas'] as int? ?? 0,
      quatroOuMaisEstrelas:   json['quatro_ou_mais_estrelas'] as int? ?? 0,
    );
  }

  String get mediaFormatada {
    if (mediaAvaliacoes == null) return '—';
    return mediaAvaliacoes!.toStringAsFixed(1);
  }

  String get label {
    if (totalAvaliacoes == 0) return 'Sem avaliações ainda';
    final media = mediaFormatada;
    return '$media ($totalAvaliacoes ${totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'})';
  }

  double get percentualCincoEstrelas {
    if (totalAvaliacoes == 0) return 0;
    return (cincoEstrelas / totalAvaliacoes) * 100;
  }
}