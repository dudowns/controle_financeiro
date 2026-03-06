// lib/models/renda_fixa_model.dart

// Enum para tipos de renda fixa
enum TipoRendaFixa {
  cdb,
  lci,
  lca,
  tesouroPrefixado,
  tesouroSelic,
  tesouroIPCA,
}

// Enum para indexadores
enum Indexador {
  preFixado,
  posFixadoCDI,
  ipca,
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
  // 🔥 REMOVIDO: final String? observacao; (não existe no banco)

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
    // 🔥 REMOVIDO: this.observacao,
    this.rendimentoBruto,
    this.iof,
    this.ir,
    this.rendimentoLiquido,
    this.valorFinal,
  });

  // Calcular dias úteis aproximados
  int get diasUteis {
    final diasCorridos = dataVencimento.difference(dataAplicacao).inDays;
    return (diasCorridos * 252 / 365).round();
  }

  // Verificar se é isento de IR (LCI/LCA)
  bool get isIsento => tipo == TipoRendaFixa.lci || tipo == TipoRendaFixa.lca;

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
        // 🔥 REMOVIDO: 'observacao': observacao,
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
        valorAplicado: json['valor'].toDouble(),
        taxa: json['taxa'].toDouble(),
        dataAplicacao: DateTime.parse(json['data_aplicacao']),
        dataVencimento: DateTime.parse(json['data_vencimento']),
        liquidezDiaria: json['liquidez'] == 'Diária',
        // 🔥 REMOVIDO: observacao: json['observacao'],
        rendimentoBruto: json['rendimento_bruto']?.toDouble(),
        iof: json['iof']?.toDouble(),
        ir: json['ir']?.toDouble(),
        rendimentoLiquido: json['rendimento_liquido']?.toDouble(),
        valorFinal: json['valor_final']?.toDouble(),
      );
}
