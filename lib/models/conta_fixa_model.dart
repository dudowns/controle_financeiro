// lib/models/conta_fixa_model.dart

enum StatusParcela {
  paga,
  aPagar,
  atrasada,
  futura,
}

class Parcela {
  int numero;
  DateTime dataVencimento;
  StatusParcela status;
  double? valorPago;
  DateTime? dataPagamento;

  Parcela({
    required this.numero,
    required this.dataVencimento,
    required this.status,
    this.valorPago,
    this.dataPagamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'dataVencimento': dataVencimento.toIso8601String(),
      'status': status.index,
      'valorPago': valorPago,
      'dataPagamento': dataPagamento?.toIso8601String(),
    };
  }

  factory Parcela.fromMap(Map<String, dynamic> map) {
    return Parcela(
      numero: map['numero'],
      dataVencimento: DateTime.parse(map['dataVencimento']),
      status: StatusParcela.values[map['status']],
      valorPago: map['valorPago']?.toDouble(),
      dataPagamento: map['dataPagamento'] != null
          ? DateTime.parse(map['dataPagamento'])
          : null,
    );
  }
}

class ContaFixa {
  int? id;
  String nome;
  double valorTotal;
  int totalParcelas;
  DateTime dataInicio;
  String? categoria;
  String? observacao;
  List<Parcela> parcelas;

  ContaFixa({
    this.id,
    required this.nome,
    required this.valorTotal,
    required this.totalParcelas,
    required this.dataInicio,
    this.categoria,
    this.observacao,
    required this.parcelas,
  });

  double get valorPago {
    return parcelas
        .where((p) => p.status == StatusParcela.paga)
        .fold(0.0, (sum, p) => sum + (p.valorPago ?? 0));
  }

  int get parcelasPagas {
    return parcelas.where((p) => p.status == StatusParcela.paga).length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valorTotal': valorTotal,
      'totalParcelas': totalParcelas,
      'dataInicio': dataInicio.toIso8601String(),
      'categoria': categoria,
      'observacao': observacao,
      'parcelas': parcelas.map((p) => p.toMap()).toList(),
    };
  }

  factory ContaFixa.fromMap(Map<String, dynamic> map) {
    return ContaFixa(
      id: map['id'],
      nome: map['nome'],
      valorTotal: map['valorTotal'],
      totalParcelas: map['totalParcelas'],
      dataInicio: DateTime.parse(map['dataInicio']),
      categoria: map['categoria'],
      observacao: map['observacao'],
      parcelas:
          (map['parcelas'] as List).map((p) => Parcela.fromMap(p)).toList(),
    );
  }
}
