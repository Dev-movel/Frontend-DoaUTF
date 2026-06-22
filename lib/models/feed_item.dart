class FeedItem {
  final int id;
  final String titulo;
  final List<String> fotos;
  final String status;
  final String categoria;
  final String? descricao;
  final int? doadorId;
  final String doadorNome;
  final String localizacao;
  final DateTime criadoEm;
  final String? estadoConservacao;
  final int? solicitacaoId;

  const FeedItem({
    required this.id,
    required this.titulo,
    this.fotos = const [],
    required this.status,
    required this.categoria,
    this.descricao,
    this.doadorId,
    required this.doadorNome,
    required this.localizacao,
    required this.criadoEm,
    this.estadoConservacao,
    this.solicitacaoId,
  });

  String? get fotoUrl => fotos.isNotEmpty ? fotos.first : null;

  FeedItem copyWith({int? solicitacaoId}) => FeedItem(
        id: id,
        titulo: titulo,
        fotos: fotos,
        status: status,
        categoria: categoria,
        descricao: descricao,
        doadorId: doadorId,
        doadorNome: doadorNome,
        localizacao: localizacao,
        criadoEm: criadoEm,
        estadoConservacao: estadoConservacao,
        solicitacaoId: solicitacaoId,
      );

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo'] ?? 'Sem título',
      fotos: _parseFotos(json['fotos']),
      status: json['status'] ?? 'ANUNCIADO',
      categoria: json['categoria']?['nome'] ?? 'Outros',
      descricao: json['descricao'],
      doadorId: json['doador']?['id'] as int?,
      doadorNome: json['doador']?['nome'] ?? 'Usuário',
      localizacao: json['local_retirada'] ?? 'Não informado',
      criadoEm: _parseDataUtc(json['criado_em']),
      estadoConservacao: json['estado_conservacao'],
      solicitacaoId: json['solicitacao_id'] as int?,
    );
  }

  static DateTime _parseDataUtc(dynamic raw) {
    if (raw == null) return DateTime.now().toUtc();
    final s = raw.toString();
    // Se não tiver sufixo de timezone, assume UTC
    final utcStr = (s.endsWith('Z') || s.contains('+')) ? s : '${s}Z';
    return DateTime.tryParse(utcStr)?.toUtc() ?? DateTime.now().toUtc();
  }

  static List<String> _parseFotos(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      if (e is String) return e;
      if (e is Map) return e['url']?.toString() ?? '';
      return '';
    }).where((s) => s.isNotEmpty).toList();
  }

  String get tempoAtras {
    final diff = DateTime.now().toUtc().difference(criadoEm);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  String get estadoLabel => switch (estadoConservacao?.toLowerCase()) {
    'novo'              => 'Novo',
    'usado'             => 'Usado',
    'precisa_de_reparo' => 'Precisa de reparo',
    _                   => estadoConservacao ?? 'Não informado',
  };
}
