// lib/screens/detalhes_renda_fixa.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/renda_fixa_model.dart';
import '../services/renda_fixa_diaria.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

class DetalhesRendaFixaScreen extends StatefulWidget {
  final RendaFixaModel investimento;

  const DetalhesRendaFixaScreen({super.key, required this.investimento});

  @override
  State<DetalhesRendaFixaScreen> createState() =>
      _DetalhesRendaFixaScreenState();
}

class _DetalhesRendaFixaScreenState extends State<DetalhesRendaFixaScreen> {
  late List<Map<String, dynamic>> _evolucao;
  late double _valorHoje;
  late double _rendimentoHoje;
  late double _irParcial;
  late double _iofParcial;

  @override
  void initState() {
    super.initState();
    _calcularDados();
  }

  void _calcularDados() {
    final hoje = DateTime.now();
    _valorHoje = RendaFixaDiaria.calcularValorEm(
      widget.investimento,
      hoje,
    );
    _rendimentoHoje = _valorHoje - widget.investimento.valorAplicado;
    _irParcial = RendaFixaDiaria.calcularIRParcial(
      widget.investimento,
      hoje,
    );
    _iofParcial = _calcularIOFParcial();
    _evolucao = RendaFixaDiaria.gerarEvolucaoDiaria(
      widget.investimento,
      maxPontos: 20,
    );
  }

  double _calcularIOFParcial() {
    final diasUteis = _calcularDiasUteisAteHoje();
    if (diasUteis >= 30) return 0;

    final aliquota = (30 - diasUteis) / 30 * 0.96;
    return _rendimentoHoje * aliquota;
  }

  int _calcularDiasUteisAteHoje() {
    int diasUteis = 0;
    DateTime atual = widget.investimento.dataAplicacao;
    final hoje = DateTime.now();

    while (atual.isBefore(hoje) || atual.isAtSameMomentAs(hoje)) {
      if (atual.weekday != DateTime.saturday &&
          atual.weekday != DateTime.sunday) {
        diasUteis++;
      }
      atual = atual.add(const Duration(days: 1));
    }
    return diasUteis;
  }

  @override
  Widget build(BuildContext context) {
    final diasAplicados =
        DateTime.now().difference(widget.investimento.dataAplicacao).inDays;
    final diasTotais = widget.investimento.dataVencimento
        .difference(widget.investimento.dataAplicacao)
        .inDays;
    final progresso = diasAplicados / diasTotais;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.investimento.nome),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card do valor atual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VALOR ATUAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(_valorHoje),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _rendimentoHoje >= 0
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _rendimentoHoje >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: _rendimentoHoje >= 0
                                  ? Colors.green[200]
                                  : Colors.red[200],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              CurrencyFormatter.format(_rendimentoHoje),
                              style: TextStyle(
                                color: _rendimentoHoje >= 0
                                    ? Colors.green[200]
                                    : Colors.red[200],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'desde a aplicação',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Barra de progresso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progresso',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progresso * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progresso,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF6A1B9A),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.formatDate(
                            widget.investimento.dataAplicacao),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        DateFormatter.formatDate(
                            widget.investimento.dataVencimento),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Gráfico de evolução
            if (_evolucao.isNotEmpty) ...[
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < _evolucao.length) {
                              final data =
                                  _evolucao[value.toInt()]['data'] as DateTime;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('dd/MM').format(data),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 22,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _evolucao.asMap().entries.map((e) {
                          return FlSpot(
                            e.key.toDouble(),
                            e.value['valor'],
                          );
                        }).toList(),
                        isCurved: true,
                        color: const Color(0xFF6A1B9A),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Cards de informação
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildInfoCard(
                  'Aplicação',
                  CurrencyFormatter.format(widget.investimento.valorAplicado),
                  Icons.account_balance,
                  Colors.blue,
                ),
                _buildInfoCard(
                  'Taxa',
                  _formatarTaxa(),
                  Icons.percent,
                  Colors.green,
                ),
                _buildInfoCard(
                  'Rendimento Hoje',
                  CurrencyFormatter.format(_calcularRendimentoHoje()),
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildInfoCard(
                  'IR (parcial)',
                  CurrencyFormatter.format(_irParcial),
                  Icons.receipt,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Detalhes completos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetalheLinha(
                    'Indexador',
                    _getIndexadorTexto(),
                  ),
                  _buildDetalheLinha(
                    'Liquidez',
                    widget.investimento.liquidezDiaria
                        ? 'Diária'
                        : 'No vencimento',
                  ),
                  _buildDetalheLinha(
                    'Dias úteis',
                    '${_calcularDiasUteisAteHoje()} de ${widget.investimento.diasUteis}',
                  ),
                  if (!widget.investimento.isIsento) ...[
                    const Divider(height: 24),
                    _buildDetalheLinha(
                      'Rendimento Bruto',
                      CurrencyFormatter.format(_rendimentoHoje),
                      cor: Colors.green,
                    ),
                    _buildDetalheLinha(
                      'IOF',
                      '-${CurrencyFormatter.format(_iofParcial)}',
                      cor: Colors.red,
                    ),
                    _buildDetalheLinha(
                      'IR',
                      '-${CurrencyFormatter.format(_irParcial)}',
                      cor: Colors.red,
                    ),
                    const Divider(height: 16),
                    _buildDetalheLinha(
                      'Rendimento Líquido',
                      CurrencyFormatter.format(
                          _rendimentoHoje - _iofParcial - _irParcial),
                      cor: Colors.green,
                      negrito: true,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetalheLinha(
                    'Valor Final Projetado',
                    CurrencyFormatter.format(
                        widget.investimento.valorFinal ?? 0),
                    cor: const Color(0xFF6A1B9A),
                    negrito: true,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: cor, size: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheLinha(
    String label,
    String value, {
    Color? cor,
    bool negrito = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize - 2,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
              color: cor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  double _calcularRendimentoHoje() {
    final ontem = DateTime.now().subtract(const Duration(days: 1));
    final valorOntem = RendaFixaDiaria.calcularValorEm(
      widget.investimento,
      ontem,
    );
    return _valorHoje - valorOntem;
  }

  String _formatarTaxa() {
    switch (widget.investimento.indexador) {
      case Indexador.preFixado:
        return '${widget.investimento.taxa.toStringAsFixed(2)}% a.a.';
      case Indexador.posFixadoCDI:
        return '${widget.investimento.taxa.toStringAsFixed(0)}% do CDI';
      case Indexador.ipca:
        return 'IPCA + ${widget.investimento.taxa.toStringAsFixed(2)}%';
    }
  }

  String _getIndexadorTexto() {
    switch (widget.investimento.indexador) {
      case Indexador.preFixado:
        return 'Prefixado';
      case Indexador.posFixadoCDI:
        return 'Pós-fixado (% CDI)';
      case Indexador.ipca:
        return 'IPCA+';
    }
  }
}
