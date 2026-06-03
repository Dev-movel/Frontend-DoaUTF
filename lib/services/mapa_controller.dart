// lib/services/mapa_controller.dart
import 'package:flutter/material.dart';

class PontoNoMapa {
  final String nome;
  final Offset posicao;
  final List<String> aliases; // nomes alternativos que também batem neste ponto

  const PontoNoMapa({
    required this.nome,
    required this.posicao,
    this.aliases = const [],
  });

  /// Verifica se o nome informado bate com o nome principal ou algum alias
  bool correspondeA(String busca) {
    final b = busca.toLowerCase().trim();
    if (nome.toLowerCase() == b) return true;
    return aliases.any((a) => a.toLowerCase() == b);
  }
}

const List<PontoNoMapa> pontosDoMapa = [
  PontoNoMapa(nome: 'Bloco A',               posicao: Offset(1054, 946)),
  PontoNoMapa(
    nome: 'Bloco B',
    posicao: Offset(714, 748),
    aliases: ['Bloco B - UTFPR'],   // adicione aqui outros nomes que o backend possa mandar
  ),
  PontoNoMapa(nome: 'Bloco C',               posicao: Offset(872,  746)),
  PontoNoMapa(nome: 'Bloco D',               posicao: Offset(1016, 748)),
  PontoNoMapa(nome: 'Bloco E',               posicao: Offset(1174, 750)),
  PontoNoMapa(nome: 'Bloco F',               posicao: Offset(1320, 748)),
  PontoNoMapa(nome: 'Bloco G',               posicao: Offset(1018, 450)),
  PontoNoMapa(nome: 'Biblioteca',            posicao: Offset(1018, 700)),
  PontoNoMapa(nome: 'Centro de Convivência', posicao: Offset(1508, 1066)),
  PontoNoMapa(nome: 'Aquário',               posicao: Offset(1004, 948)),
  PontoNoMapa(nome: 'RU',                    posicao: Offset(1656, 1062)),
];

/// Busca pelo nome exato ou por qualquer alias registrado
PontoNoMapa? buscarPontoPorNome(String nome) {
  try {
    return pontosDoMapa.firstWhere((p) => p.correspondeA(nome));
  } catch (_) {
    return null;
  }
}