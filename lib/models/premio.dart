class Premio {
  final int id;
  final String nome;
  final int custo;
  final String imagem;

  const Premio({
    required this.id,
    required this.nome,
    required this.custo,
    required this.imagem,
  });

  static const List<Premio> catalogo = [
    Premio(id: 1,  nome: 'Post-it Doai',       custo: 50,   imagem: 'assets/images/01_post-it.png'),
    Premio(id: 2,  nome: 'Caneta Doai',         custo: 100,  imagem: 'assets/images/02_caneta.png'),
    Premio(id: 3,  nome: 'Botton Doai',         custo: 150,  imagem: 'assets/images/03_botton.png'),
    Premio(id: 4,  nome: 'Caderno Doai',        custo: 200,  imagem: 'assets/images/04_caderno.png'),
    Premio(id: 5,  nome: 'Copo Doai',           custo: 300,  imagem: 'assets/images/05_copo.png'),
    Premio(id: 6,  nome: 'Ecobag Doai',         custo: 400,  imagem: 'assets/images/06_ecobag.png'),
    Premio(id: 7,  nome: 'Caneca Doai',         custo: 500,  imagem: 'assets/images/07_caneca.png'),
    Premio(id: 8,  nome: 'Guarda-chuva Doai',   custo: 700,  imagem: 'assets/images/08_guarda-chuva.png'),
    Premio(id: 9,  nome: 'Camiseta UTF/Doai',   custo: 1000, imagem: 'assets/images/11_camiseta.png'),
    Premio(id: 10, nome: 'Notebook',            custo: 2500, imagem: 'assets/images/12_notebook.png'),
  ];
}
