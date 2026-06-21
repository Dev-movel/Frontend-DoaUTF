class Notificacao {
  final int id;
  final String tipo;
  final String mensagem;
  final Map<String, dynamic> dados;
  final bool lida;
  final DateTime criadoEm;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.mensagem,
    required this.dados,
    required this.lida,
    required this.criadoEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: int.parse(json['id'].toString()),
      tipo: json['tipo'] as String,
      mensagem: json['mensagem'] as String,
      dados: (json['dados'] as Map<String, dynamic>?) ?? {},
      lida: json['lida'] as bool,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }
}
