// lib/models/conta_fixa_model.dart

enum StatusParcela {
  paga,
  aPagar,
  atrasada, // 🔥 NOVO STATUS!
  futura,
}

class Parcela {
  final int numero;
  final DateTime dataVencimento;
  StatusParcela status;
  DateTime? dataPagamento;
  double? valorPago;

  Parcela({
    required this.numero,
    required this.dataVencimento,
    this.status = StatusParcela.futura,
    this.dataPagamento,
    this.valorPago,
  });

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'dataVencimento': dataVencimento.toIso8601String(),
        'status': status.index,
        'dataPagamento': dataPagamento?.toIso8601String(),
        'valorPago': valorPago,
      };

  factory Parcela.fromJson(Map<String, dynamic> json) => Parcela(
        numero: json['numero'],
        dataVencimento: DateTime.parse(json['dataVencimento']),
        status: StatusParcela.values[json['status']],
        dataPagamento: json['dataPagamento'] != null
            ? DateTime.parse(json['dataPagamento'])
            : null,
        valorPago: json['valorPago']?.toDouble(),
      );
}

class ContaFixa {
  final int? id;
  final String nome;
  final double valorTotal;
  final int totalParcelas;
  final DateTime dataInicio;
  final String? categoria;
  final String? observacao;
  final List<Parcela> parcelas;

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

  int get parcelasPagas =>
      parcelas.where((p) => p.status == StatusParcela.paga).length;
  double get valorPago => parcelas
      .where((p) => p.status == StatusParcela.paga)
      .fold(0, (sum, p) => sum + (p.valorPago ?? valorParcelas));

  double get valorParcelas => valorTotal / totalParcelas;
  double get saldoRestante => valorTotal - valorPago;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'valorTotal': valorTotal,
        'totalParcelas': totalParcelas,
        'dataInicio': dataInicio.toIso8601String(),
        'categoria': categoria,
        'observacao': observacao,
        'parcelas': parcelas.map((p) => p.toJson()).toList(),
      };

  factory ContaFixa.fromJson(Map<String, dynamic> json) => ContaFixa(
        id: json['id'],
        nome: json['nome'],
        valorTotal: json['valorTotal'].toDouble(),
        totalParcelas: json['totalParcelas'],
        dataInicio: DateTime.parse(json['dataInicio']),
        categoria: json['categoria'],
        observacao: json['observacao'],
        parcelas:
            (json['parcelas'] as List).map((p) => Parcela.fromJson(p)).toList(),
      );
}
