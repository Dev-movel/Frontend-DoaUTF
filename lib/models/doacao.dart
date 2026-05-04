class Doacao {
  final int id;
  final String titulo;
  final String? fotoUrl;
  final String status;

  Doacao({
    required this.id,
    required this.titulo,
    this.fotoUrl,
    required this.status,
  });

  factory Doacao.fromJson(Map<String, dynamic> json) {
    return Doacao(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sem título',
      fotoUrl: json['foto_url'],
      status: json['status'] ?? 'DESCONHECIDO',
    );
  }
}