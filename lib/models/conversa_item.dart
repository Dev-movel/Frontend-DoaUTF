class ConversaItem {
  final int solicitacaoId;
  final int itemId;
  final String tituloItem;
  final String nomeOutroUsuario;
  final String? ultimaMensagem;
  final DateTime? ultimaMensagemEm;
  final bool encerrada;
  final int naoLidas;

  const ConversaItem({
    required this.solicitacaoId,
    required this.itemId,
    required this.tituloItem,
    required this.nomeOutroUsuario,
    this.ultimaMensagem,
    this.ultimaMensagemEm,
    required this.encerrada,
    required this.naoLidas,
  });

  factory ConversaItem.fromJson(Map<String, dynamic> json) {
    return ConversaItem(
      solicitacaoId: json['solicitacao_id'] as int,
      itemId: json['item_id'] as int,
      tituloItem: json['titulo_item'] as String? ?? 'Item',
      nomeOutroUsuario: json['nome_outro_usuario'] as String? ?? 'Usuário',
      ultimaMensagem: json['ultima_mensagem'] as String?,
      ultimaMensagemEm: json['ultima_mensagem_em'] != null
          ? DateTime.tryParse(json['ultima_mensagem_em'].toString())?.toLocal()
          : null,
      encerrada: json['encerrada'] as bool? ?? false,
      naoLidas: int.tryParse('${json['nao_lidas'] ?? 0}') ?? 0,
    );
  }
}
