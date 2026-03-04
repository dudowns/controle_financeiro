import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';

class RendaFixaDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSalvar;

  const RendaFixaDialog({super.key, required this.onSalvar});

  @override
  State<RendaFixaDialog> createState() => _RendaFixaDialogState();
}

class _RendaFixaDialogState extends State<RendaFixaDialog> {
  final DBHelper db = DBHelper();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _taxaController = TextEditingController();

  DateTime _dataAplicacao = DateTime.now();
  DateTime _dataVencimento = DateTime.now().add(const Duration(days: 365));

  String _tipoRenda = 'CDB';
  String _indexador = 'Pós-fixado';
  String _liquidezSelecionada = 'Diária';
  bool _isLCI = false;

  final List<String> _tiposRenda = [
    'CDB',
    'LCI',
    'LCA',
    'Tesouro Selic',
    'Tesouro IPCA+',
    'Tesouro Prefixado',
    'Poupança',
  ];

  final List<String> _indexadores = [
    'Pós-fixado',
    'Prefixado',
    'IPCA+',
  ];

  final List<String> _liquidezOpcoes = [
    'Diária',
    'No vencimento',
  ];

  double _rendimentoBruto = 0;
  double _iof = 0;
  double _ir = 0;
  double _rendimentoLiquido = 0;
  double _valorFinal = 0;

  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(valor);
  }

  void _calcularSimulacao() {
    try {
      double valor = double.parse(_valorController.text.replaceAll(',', '.'));
      double taxa = double.parse(_taxaController.text.replaceAll(',', '.'));
      int dias = _dataVencimento.difference(_dataAplicacao).inDays;

      bool isLCI = _tipoRenda == 'LCI' || _tipoRenda == 'LCA';

      final resultado = db.simularRendaFixa(
        valor: valor,
        taxa: taxa,
        dias: dias,
        tipo: _tipoRenda,
        isLCI: isLCI,
      );

      setState(() {
        _rendimentoBruto = resultado['rendimentoBruto']!;
        _iof = resultado['iof']!;
        _ir = resultado['ir']!;
        _rendimentoLiquido = resultado['rendimentoLiquido']!;
        _valorFinal = resultado['valorFinal']!;
      });
    } catch (e) {
      // Silencia erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Renda Fixa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Investimento',
                hintText: 'Ex: CDB Banco X',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _tipoRenda,
              decoration: const InputDecoration(
                labelText: 'Tipo de Renda Fixa',
                border: OutlineInputBorder(),
              ),
              items: _tiposRenda.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoRenda = value!;
                  _isLCI = value == 'LCI' || value == 'LCA';
                });
                _calcularSimulacao();
              },
            ),
            const SizedBox(height: 12),
            
            if (_tipoRenda == 'CDB' || _tipoRenda == 'Tesouro IPCA+') ...[
              DropdownButtonFormField<String>(
                value: _indexador,
                decoration: const InputDecoration(
                  labelText: 'Indexador',
                  border: OutlineInputBorder(),
                ),
                items: _indexadores.map((idx) {
                  return DropdownMenuItem(
                    value: idx,
                    child: Text(idx),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _indexador = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            
            TextField(
              controller: _valorController,
              decoration: const InputDecoration(
                labelText: 'Percentual do CDI (%)',
                hintText: 'Ex: 103 para 103% do CDI',
                suffixText: '% do CDI',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularSimulacao(),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _taxaController,
              decoration: const InputDecoration(
                labelText: 'Taxa (%)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularSimulacao(),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _liquidezSelecionada,
              decoration: const InputDecoration(
                labelText: 'Liquidez',
                border: OutlineInputBorder(),
              ),
              items: _liquidezOpcoes.map((opcao) {
                return DropdownMenuItem(
                  value: opcao,
                  child: Text(opcao),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _liquidezSelecionada = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildDataField('Aplicação', _dataAplicacao, (date) {
                    setState(() {
                      _dataAplicacao = date;
                    });
                    _calcularSimulacao();
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDataField('Vencimento', _dataVencimento, (date) {
                    setState(() {
                      _dataVencimento = date;
                    });
                    _calcularSimulacao();
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (_rendimentoLiquido > 0) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetalhe('Rendimento Bruto', _rendimentoBruto, Colors.black87),
                    if (_iof > 0) _buildDetalhe('IOF', -_iof, Colors.red),
                    if (_ir > 0) _buildDetalhe('IR', -_ir, Colors.red),
                    const Divider(height: 16),
                    _buildDetalhe('Rendimento Líquido', _rendimentoLiquido, Colors.green, isTotal: true),
                    _buildDetalhe('Valor Final', _valorFinal, Colors.teal, isTotal: true),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nomeController.text.isEmpty ||
                _valorController.text.isEmpty ||
                _taxaController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preencha todos os campos!'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            double valor = double.parse(_valorController.text.replaceAll(',', '.'));
            double taxa = double.parse(_taxaController.text.replaceAll(',', '.'));
            int dias = _dataVencimento.difference(_dataAplicacao).inDays;

            widget.onSalvar({
              'nome': _nomeController.text,
              'tipo_renda': _tipoRenda,
              'indexador': _indexador,
              'liquidez': _liquidezSelecionada,
              'valor': valor,
              'taxa': taxa,
              'data_aplicacao': _dataAplicacao.toIso8601String(),
              'data_vencimento': _dataVencimento.toIso8601String(),
              'dias': dias,
              'rendimento_bruto': _rendimentoBruto,
              'iof': _iof,
              'ir': _ir,
              'rendimento_liquido': _rendimentoLiquido,
              'valor_final': _valorFinal,
              'is_lci': _isLCI ? 1 : 0,
            });
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _buildDataField(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final newDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (newDate != null) onSelect(newDate);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhe(String label, double valor, Color cor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 13 : 12, color: cor)),
          Text(
            _formatarValor(valor),
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}