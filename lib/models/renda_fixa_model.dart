// lib/models/renda_fixa_model.dart

import 'package:flutter/material.dart'; // 🔥 IMPORT ADICIONADO para cores
import 'package:intl/intl.dart'; // 🔥 IMPORT ADICIONADO para formatação

// Enum para tipos de renda fixa
enum TipoRendaFixa {
  cdb,
  lci,
  lca,
  tesouroPrefixado,
  tesouroSelic,
  tesouroIPCA,
}

// 🔥 Extension para TipoRendaFixa
extension TipoRendaFixaExtension on TipoRendaFixa {
  String get nome {
    switch (this) {
      case TipoRendaFixa.cdb:
        return 'CDB';
      case TipoRendaFixa.lci:
        return 'LCI';
      case TipoRendaFixa.lca:
        return 'LCA';
      case TipoRendaFixa.tesouroPrefixado:
        return 'Tesouro Prefixado';
      case TipoRendaFixa.tesouroSelic:
        return 'Tesouro Selic';
      case TipoRendaFixa.tesouroIPCA:
        return 'Tesouro IPCA+';
    }
  }

  Color get cor {
    switch (this) {
      case TipoRendaFixa.cdb:
        return Colors.blue;
      case TipoRendaFixa.lci:
      case TipoRendaFixa.lca:
        return Colors.green;
      case TipoRendaFixa.tesouroPrefixado:
      case TipoRendaFixa.tesouroSelic:
      case TipoRendaFixa.tesouroIPCA:
        return Colors.orange;
    }
  }

  IconData get icone {
    switch (this) {
      case TipoRendaFixa.cdb:
        return Icons.account_balance;
      case TipoRendaFixa.lci:
      case TipoRendaFixa.lca:
        return Icons.apartment;
      case TipoRendaFixa.tesouroPrefixado:
      case TipoRendaFixa.tesouroSelic:
      case TipoRendaFixa.tesouroIPCA:
        return Icons.attach_money;
    }
  }

  bool get isIsento {
    return this == TipoRendaFixa.lci || this == TipoRendaFixa.lca;
  }
}

// Enum para indexadores
enum Indexador {
  preFixado,
  posFixadoCDI,
  ipca,
}

// 🔥 Extension para Indexador
extension IndexadorExtension on Indexador {
  String get nome {
    switch (this) {
      case Indexador.preFixado:
        return 'Prefixado';
      case Indexador.posFixadoCDI:
        return '% CDI';
      case Indexador.ipca:
        return 'IPCA+';
    }
  }

  String get simbolo {
    switch (this) {
      case Indexador.preFixado:
        return '% a.a.';
      case Indexador.posFixadoCDI:
        return '% do CDI';
      case Indexador.ipca:
        return '%';
    }
  }
}

// Modelo principal
class RendaFixaModel {
  final int? id;
  final String nome;
  final TipoRendaFixa tipo;
  final Indexador indexador;
  final double valorAplicado;
  final double taxa; // % do CDI ou taxa fixa
  final DateTime dataAplicacao;
  final DateTime dataVencimento;
  final bool liquidezDiaria;

  // Campos calculados
  final double? rendimentoBruto;
  final double? iof;
  final double? ir;
  final double? rendimentoLiquido;
  final double? valorFinal;

  RendaFixaModel({
    this.id,
    required this.nome,
    required this.tipo,
    required this.indexador,
    required this.valorAplicado,
    required this.taxa,
    required this.dataAplicacao,
    required this.dataVencimento,
    required this.liquidezDiaria,
    this.rendimentoBruto,
    this.iof,
    this.ir,
    this.rendimentoLiquido,
    this.valorFinal,
  });

  // Getters calculados
  int get diasTotais {
    return dataVencimento.difference(dataAplicacao).inDays;
  }

  int get diasDecorridos {
    final hoje = DateTime.now();
    if (hoje.isBefore(dataAplicacao)) return 0;
    if (hoje.isAfter(dataVencimento)) return diasTotais;
    return hoje.difference(dataAplicacao).inDays;
  }

  double get progresso {
    if (diasTotais == 0) return 0;
    return diasDecorridos / diasTotais;
  }

  double get rendimentoAtual {
    if (valorFinal == null) return 0;
    return valorFinal! - valorAplicado;
  }

  double get rendimentoPercentual {
    if (valorAplicado == 0) return 0;
    return (rendimentoAtual / valorAplicado) * 100;
  }

  // Calcular dias úteis aproximados
  int get diasUteis {
    final diasCorridos = dataVencimento.difference(dataAplicacao).inDays;
    return (diasCorridos * 252 / 365).round();
  }

  // Verificar se é isento de IR (LCI/LCA)
  bool get isIsento => tipo.isIsento;

  // Verificar se já venceu
  bool get isVencido => DateTime.now().isAfter(dataVencimento);

  // Verificar se está ativo
  bool get isAtivo => !isVencido;

  // Converter para JSON (salvar no banco)
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo_renda': tipo.index,
        'indexador': indexador.index,
        'valor': valorAplicado,
        'taxa': taxa,
        'data_aplicacao': dataAplicacao.toIso8601String(),
        'data_vencimento': dataVencimento.toIso8601String(),
        'liquidez': liquidezDiaria ? 'Diária' : 'No vencimento',
        'is_lci': isIsento ? 1 : 0,
        'rendimento_bruto': rendimentoBruto,
        'iof': iof,
        'ir': ir,
        'rendimento_liquido': rendimentoLiquido,
        'valor_final': valorFinal,
      };

  // Criar modelo a partir do JSON (ler do banco)
  factory RendaFixaModel.fromJson(Map<String, dynamic> json) => RendaFixaModel(
        id: json['id'],
        nome: json['nome'],
        tipo: TipoRendaFixa.values[json['tipo_renda']],
        indexador: Indexador.values[json['indexador']],
        valorAplicado: (json['valor'] as num).toDouble(),
        taxa: (json['taxa'] as num).toDouble(),
        dataAplicacao: DateTime.parse(json['data_aplicacao']),
        dataVencimento: DateTime.parse(json['data_vencimento']),
        liquidezDiaria: json['liquidez'] == 'Diária',
        rendimentoBruto: json['rendimento_bruto']?.toDouble(),
        iof: json['iof']?.toDouble(),
        ir: json['ir']?.toDouble(),
        rendimentoLiquido: json['rendimento_liquido']?.toDouble(),
        valorFinal: json['valor_final']?.toDouble(),
      );

  // 🔥 Cópia com alterações
  RendaFixaModel copyWith({
    int? id,
    String? nome,
    TipoRendaFixa? tipo,
    Indexador? indexador,
    double? valorAplicado,
    double? taxa,
    DateTime? dataAplicacao,
    DateTime? dataVencimento,
    bool? liquidezDiaria,
    double? rendimentoBruto,
    double? iof,
    double? ir,
    double? rendimentoLiquido,
    double? valorFinal,
  }) {
    return RendaFixaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      indexador: indexador ?? this.indexador,
      valorAplicado: valorAplicado ?? this.valorAplicado,
      taxa: taxa ?? this.taxa,
      dataAplicacao: dataAplicacao ?? this.dataAplicacao,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      liquidezDiaria: liquidezDiaria ?? this.liquidezDiaria,
      rendimentoBruto: rendimentoBruto ?? this.rendimentoBruto,
      iof: iof ?? this.iof,
      ir: ir ?? this.ir,
      rendimentoLiquido: rendimentoLiquido ?? this.rendimentoLiquido,
      valorFinal: valorFinal ?? this.valorFinal,
    );
  }
}
