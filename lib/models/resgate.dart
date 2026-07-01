class Resgate {
  final int id;
  final int premioId;
  final String premioNome;
  final int pontosGastos;
  final String codigo;
  final String status; // 'pendente' | 'retirado'
  final DateTime criadoEm;

  const Resgate({
    required this.id,
    required this.premioId,
    required this.premioNome,
    required this.pontosGastos,
    required this.codigo,
    required this.status,
    required this.criadoEm,
  });

  factory Resgate.fromJson(Map<String, dynamic> json) {
    return Resgate(
      id: json['id'] as int,
      premioId: json['premio_id'] as int,
      premioNome: json['premio_nome'] as String? ?? '',
      pontosGastos: json['pontos_gastos'] as int? ?? 0,
      codigo: json['codigo'] as String? ?? '',
      status: json['status'] as String? ?? 'pendente',
      criadoEm: DateTime.tryParse(json['criado_em']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isPendente => status == 'pendente';
}
