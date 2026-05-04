class Endereco {
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;

  Endereco({
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      rua: json['rua'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (rua != null) 'rua': rua,
      if (numero != null) 'numero': numero,
      if (bairro != null) 'bairro': bairro,
      if (cidade != null) 'cidade': cidade,
    };
  }
}

class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? whatsapp;
  final String? dataNascimento;
  final Endereco? endereco;
  final String? createdAt;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.whatsapp,
    this.dataNascimento,
    this.endereco,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      whatsapp: json['whatsapp'],
      dataNascimento: json['data_nascimento'],
      endereco: json['endereco'] != null 
          ? Endereco.fromJson(json['endereco']) 
          : null,
      createdAt: json['created_at'],
    );
  }
}