// lib/models/conta_fixa_model.dart

import 'package:flutter/material.dart'; // 🔥 IMPORT ADICIONADO para cores se necessário
import 'package:intl/intl.dart'; // 🔥 IMPORT ADICIONADO para formatação

enum StatusParcela {
  paga,
  aPagar,
  atrasada,
  futura,
}

// 🔥 EXTENSION ÚTIL para StatusParcela
extension StatusParcelaExtension on StatusParcela {
  String get nome {
    switch (this) {
      case StatusParcela.paga:
        return 'PAGA';
      case StatusParcela.aPagar:
        return 'A PAGAR';
      case StatusParcela.atrasada:
        return 'ATRASADA';
      case StatusParcela.futura:
        return 'FUTURA';
    }
  }

  Color get cor {
    switch (this) {
      case StatusParcela.paga:
        return Colors.green;
      case StatusParcela.aPagar:
        return Colors.orange;
      case StatusParcela.atrasada:
        return Colors.red;
      case StatusParcela.futura:
        return Colors.grey;
    }
  }

  IconData get icone {
    switch (this) {
      case StatusParcela.paga:
        return Icons.check_circle;
      case StatusParcela.aPagar:
        return Icons.warning_amber;
      case StatusParcela.atrasada:
        return Icons.error;
      case StatusParcela.futura:
        return Icons.access_time;
    }
  }
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

  // 🔥 Getter para saber se está paga
  bool get isPaga => status == StatusParcela.paga;

  // 🔥 Getter para valor formatado
  String get valorFormatado {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    return formatador.format(valorPago ?? 0);
  }

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

  // 🔥 Cópia com alterações
  Parcela copyWith({
    int? numero,
    DateTime? dataVencimento,
    StatusParcela? status,
    double? valorPago,
    DateTime? dataPagamento,
  }) {
    return Parcela(
      numero: numero ?? this.numero,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      status: status ?? this.status,
      valorPago: valorPago ?? this.valorPago,
      dataPagamento: dataPagamento ?? this.dataPagamento,
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

  // Getters calculados
  double get valorPago {
    return parcelas
        .where((p) => p.status == StatusParcela.paga)
        .fold(0.0, (sum, p) => sum + (p.valorPago ?? 0));
  }

  int get parcelasPagas {
    return parcelas.where((p) => p.status == StatusParcela.paga).length;
  }

  int get parcelasAPagar {
    return parcelas.where((p) => p.status == StatusParcela.aPagar).length;
  }

  int get parcelasAtrasadas {
    return parcelas.where((p) => p.status == StatusParcela.atrasada).length;
  }

  double get valorRestante {
    return valorTotal - valorPago;
  }

  double get progresso {
    if (totalParcelas == 0) return 0;
    return parcelasPagas / totalParcelas;
  }

  // 🔥 Verifica se todas as parcelas estão pagas
  bool get estaQuitada => parcelasPagas == totalParcelas;

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

  // 🔥 Cópia com alterações
  ContaFixa copyWith({
    int? id,
    String? nome,
    double? valorTotal,
    int? totalParcelas,
    DateTime? dataInicio,
    String? categoria,
    String? observacao,
    List<Parcela>? parcelas,
  }) {
    return ContaFixa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valorTotal: valorTotal ?? this.valorTotal,
      totalParcelas: totalParcelas ?? this.totalParcelas,
      dataInicio: dataInicio ?? this.dataInicio,
      categoria: categoria ?? this.categoria,
      observacao: observacao ?? this.observacao,
      parcelas: parcelas ?? this.parcelas,
    );
  }
}
