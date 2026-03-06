// lib/screens/novo_investimento_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/renda_fixa_model.dart';
import '../services/renda_fixa_diaria.dart';
import '../utils/currency_formatter.dart';

class NovoInvestimentoDialog extends StatefulWidget {
  final Function(RendaFixaModel) onSalvar;

  const NovoInvestimentoDialog({super.key, required this.onSalvar});

  @override
  State<NovoInvestimentoDialog> createState() => _NovoInvestimentoDialogState();
}

class _NovoInvestimentoDialogState extends State<NovoInvestimentoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _taxaController = TextEditingController();

  late TipoRendaFixa _tipoSelecionado;
  late Indexador _indexadorSelecionado;
  late DateTime _dataAplicacao;
  late DateTime _dataVencimento;
  late bool _liquidezDiaria;

  Map<String, double>? _resultado;

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = TipoRendaFixa.cdb;
    _indexadorSelecionado = Indexador.posFixadoCDI;
    _dataAplicacao = DateTime.now();
    _dataVencimento = DateTime.now().add(const Duration(days: 365));
    _liquidezDiaria = false;
  }

  void _calcularSimulacao() {
    if (_valorController.text.isEmpty || _taxaController.text.isEmpty) return;

    try {
      final valor = double.parse(_valorController.text.replaceAll(',', '.'));
      final taxa = double.parse(_taxaController.text.replaceAll(',', '.'));

      final investimento = RendaFixaModel(
        nome: _nomeController.text,
        tipo: _tipoSelecionado,
        indexador: _indexadorSelecionado,
        valorAplicado: valor,
        taxa: taxa,
        dataAplicacao: _dataAplicacao,
        dataVencimento: _dataVencimento,
        liquidezDiaria: _liquidezDiaria,
      );

      final valorFinal =
          RendaFixaDiaria.calcularValorEm(investimento, _dataVencimento);
      final rendimento = valorFinal - valor;

      setState(() {
        _resultado = {
          'valorFinal': valorFinal,
          'rendimento': rendimento,
        };
      });
    } catch (e) {
      setState(() {
        _resultado = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Investimento - Renda Fixa'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Investimento',
                  hintText: 'Ex: CDB Banco X',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Campo Tipo
              DropdownButtonFormField<TipoRendaFixa>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: TipoRendaFixa.cdb, child: Text('CDB')),
                  DropdownMenuItem(
                      value: TipoRendaFixa.lci, child: Text('LCI')),
                  DropdownMenuItem(
                      value: TipoRendaFixa.lca, child: Text('LCA')),
                  DropdownMenuItem(
                      value: TipoRendaFixa.tesouroPrefixado,
                      child: Text('Tesouro Prefixado')),
                  DropdownMenuItem(
                      value: TipoRendaFixa.tesouroIPCA,
                      child: Text('Tesouro IPCA+')),
                  DropdownMenuItem(
                      value: TipoRendaFixa.tesouroSelic,
                      child: Text('Tesouro Selic')),
                ],
                onChanged: (v) {
                  setState(() {
                    _tipoSelecionado = v!;
                    if (v == TipoRendaFixa.tesouroPrefixado) {
                      _indexadorSelecionado = Indexador.preFixado;
                    } else if (v == TipoRendaFixa.tesouroIPCA) {
                      _indexadorSelecionado = Indexador.ipca;
                    } else if (v == TipoRendaFixa.tesouroSelic) {
                      _indexadorSelecionado = Indexador.posFixadoCDI;
                    }
                  });
                  _calcularSimulacao();
                },
              ),
              const SizedBox(height: 12),

              // Campo Indexador (se aplicável)
              if (_tipoSelecionado == TipoRendaFixa.cdb ||
                  _tipoSelecionado == TipoRendaFixa.lci ||
                  _tipoSelecionado == TipoRendaFixa.lca) ...[
                DropdownButtonFormField<Indexador>(
                  value: _indexadorSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Indexador',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: Indexador.preFixado, child: Text('Prefixado')),
                    DropdownMenuItem(
                        value: Indexador.posFixadoCDI, child: Text('% CDI')),
                    DropdownMenuItem(
                        value: Indexador.ipca, child: Text('IPCA+')),
                  ],
                  onChanged: (v) {
                    setState(() => _indexadorSelecionado = v!);
                    _calcularSimulacao();
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Campo Valor Aplicado
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor Aplicado (R\$)',
                  hintText: '1.000,00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calcularSimulacao(),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Campo Taxa
              TextFormField(
                controller: _taxaController,
                decoration: InputDecoration(
                  labelText: _getTaxaLabel(),
                  hintText: _getTaxaHint(),
                  border: const OutlineInputBorder(),
                  suffixText: _getTaxaSuffix(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calcularSimulacao(),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Checkbox Liquidez Diária
              CheckboxListTile(
                title: const Text('Liquidez Diária'),
                value: _liquidezDiaria,
                onChanged: (v) {
                  setState(() => _liquidezDiaria = v ?? false);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),

              // Campos de Data
              Row(
                children: [
                  Expanded(
                      child:
                          _buildDataField('Aplicação', _dataAplicacao, (date) {
                    setState(() => _dataAplicacao = date);
                    _calcularSimulacao();
                  })),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildDataField('Vencimento', _dataVencimento,
                          (date) {
                    setState(() => _dataVencimento = date);
                    _calcularSimulacao();
                  })),
                ],
              ),

              // Resultado da simulação
              if (_resultado != null) ...[
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rendimento Projetado:'),
                          Text(
                            CurrencyFormatter.format(
                                _resultado!['rendimento']!),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Valor Final:'),
                          Text(
                            CurrencyFormatter.format(
                                _resultado!['valorFinal']!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _resultado != null) {
              final investimento = RendaFixaModel(
                nome: _nomeController.text,
                tipo: _tipoSelecionado,
                indexador: _indexadorSelecionado,
                valorAplicado:
                    double.parse(_valorController.text.replaceAll(',', '.')),
                taxa: double.parse(_taxaController.text.replaceAll(',', '.')),
                dataAplicacao: _dataAplicacao,
                dataVencimento: _dataVencimento,
                liquidezDiaria: _liquidezDiaria,
                // 🔥 observacao REMOVIDO - não existe no banco
                rendimentoBruto: _resultado!['rendimento'],
                valorFinal: _resultado!['valorFinal'],
              );
              widget.onSalvar(investimento);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  String _getTaxaLabel() {
    switch (_indexadorSelecionado) {
      case Indexador.preFixado:
        return 'Taxa Prefixada (% a.a.)';
      case Indexador.posFixadoCDI:
        return 'Percentual do CDI (%)';
      case Indexador.ipca:
        return 'Taxa Real (IPCA + X%)';
    }
  }

  String _getTaxaHint() {
    switch (_indexadorSelecionado) {
      case Indexador.preFixado:
        return '13,50';
      case Indexador.posFixadoCDI:
        return '110';
      case Indexador.ipca:
        return '6,50';
    }
  }

  String _getTaxaSuffix() {
    switch (_indexadorSelecionado) {
      case Indexador.preFixado:
        return '% a.a.';
      case Indexador.posFixadoCDI:
        return '% do CDI';
      case Indexador.ipca:
        return '%';
    }
  }

  Widget _buildDataField(
      String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final newDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
          locale: const Locale('pt', 'BR'),
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
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _taxaController.dispose();
    super.dispose();
  }
}
