enum AgendamentoStatus { pendente, confirmado, concluido, cancelado }

extension AgendamentoStatusX on AgendamentoStatus {
  String get label {
    switch (this) {
      case AgendamentoStatus.pendente:   return 'Pendente';
      case AgendamentoStatus.confirmado: return 'Confirmado';
      case AgendamentoStatus.concluido:  return 'Concluído';
      case AgendamentoStatus.cancelado:  return 'Cancelado';
    }
  }

  static const Map<AgendamentoStatus, int> _colors = {
    AgendamentoStatus.pendente:   0xFFFFF3E0,
    AgendamentoStatus.confirmado: 0xFFE8F5E9, 
    AgendamentoStatus.concluido:  0xFFE3F2FD, 
    AgendamentoStatus.cancelado:  0xFFF5F5F5, 
  };

  static const Map<AgendamentoStatus, int> _textColors = {
    AgendamentoStatus.pendente:   0xFFF57C00,
    AgendamentoStatus.confirmado: 0xFF2E7D32,
    AgendamentoStatus.concluido:  0xFF1565C0,
    AgendamentoStatus.cancelado:  0xFF757575,
  };

  int get bgColor   => _colors[this]!;
  int get textColor => _textColors[this]!;

  static AgendamentoStatus fromString(String? s) {
    if (s == null) return AgendamentoStatus.pendente;
    switch (s.toLowerCase()) {
      case 'confirmado': return AgendamentoStatus.confirmado;
      case 'concluido':  return AgendamentoStatus.concluido;
      case 'cancelado':  return AgendamentoStatus.cancelado;
      default:           return AgendamentoStatus.pendente;
    }
  }
}

class Agendamento {
  final int id;
  final int itemId;
  final int doadorId;
  final int receptorId;
  final DateTime? dataHora;            
  final bool confirmacaoDoador;        
  final bool confirmacaoReceptor;      
  final AgendamentoStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Agendamento({
    required this.id,
    required this.itemId,
    required this.doadorId,
    required this.receptorId,
    this.dataHora,
    required this.confirmacaoDoador,
    required this.confirmacaoReceptor,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Agendamento(
      id:                  parseInt(json['id']),
      itemId:              parseInt(json['item_id']),
      doadorId:            parseInt(json['doador_id']),
      receptorId:          parseInt(json['receptor_id']),
      
      dataHora:            json['data_hora'] != null 
                             ? DateTime.tryParse(json['data_hora'].toString()) 
                             : null,
                             
      confirmacaoDoador:   json['confirmacao_doador'] == true || json['confirmacao_doador'] == 'true',
      confirmacaoReceptor: json['confirmacao_receptor'] == true || json['confirmacao_receptor'] == 'true',
      
      status:              AgendamentoStatusX.fromString(json['status']?.toString()),
      
      createdAt:           json['created_at'] != null 
                             ? DateTime.tryParse(json['created_at'].toString()) 
                             : null,
      updatedAt:           json['updated_at'] != null 
                             ? DateTime.tryParse(json['updated_at'].toString()) 
                             : null,
    );
  }
}