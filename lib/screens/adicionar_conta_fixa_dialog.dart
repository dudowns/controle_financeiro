// lib/screens/adicionar_conta_fixa_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conta_fixa_model.dart';
import '../utils/currency_formatter.dart';

class AdicionarContaFixaDialog extends StatefulWidget {
  final Function(ContaFixa) onSalvar;

  const AdicionarContaFixaDialog({super.key, required this.onSalvar});

  @override
  State<AdicionarContaFixaDialog> createState() =>
      _AdicionarContaFixaDialogState();
}

class _AdicionarContaFixaDialogState extends State<AdicionarContaFixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorParcelaController = TextEditingController(); // 🔥 MUDOU!
  final _categoriaController = TextEditingController();

  late DateTime _dataInicio;
  late int _totalParcelas;
  late double _valorTotalCalculado;

  @override
  void initState() {
    super.initState();
    _dataInicio = DateTime.now();
    _totalParcelas = 1;
    _valorTotalCalculado = 0;
  }

  double _parseValor(String texto) {
    try {
      return double.parse(texto.replaceAll(',', '.'));
    } catch (e) {
      return 0;
    }
  }

  void _atualizarValorTotal() {
    final valorParcela = _parseValor(_valorParcelaController.text);
    if (_totalParcelas > 0) {
      setState(() {
        _valorTotalCalculado =
            valorParcela > 0 ? valorParcela * _totalParcelas : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Conta Fixa'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nome da Conta
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Conta',
                  hintText: 'Ex: Celular Samsung',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // 🔥 AGORA O VALOR POR PARCELA É EDITÁVEL!
              TextFormField(
                controller: _valorParcelaController,
                decoration: const InputDecoration(
                  labelText: 'Valor por Parcela (R\$)',
                  hintText: '500,00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _atualizarValorTotal(),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Campo obrigatório';
                  if (_parseValor(v!) <= 0)
                    return 'Valor deve ser maior que zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Total de Parcelas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _totalParcelas.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Total de Parcelas',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {
                          _totalParcelas = int.tryParse(v) ?? 1;
                          _atualizarValorTotal();
                        });
                      },
                      validator: (v) {
                        final parcelas = int.tryParse(v ?? '');
                        if (parcelas == null) return 'Número inválido';
                        if (parcelas < 1) return 'Mínimo 1 parcela';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Valor Total',
                        border: const OutlineInputBorder(),
                        hintText: _valorTotalCalculado > 0
                            ? CurrencyFormatter.format(_valorTotalCalculado)
                            : 'R\$ 0,00',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Categoria (opcional)
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoria (opcional)',
                  hintText: 'Ex: Eletrônicos',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),

              // Data de Início
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dataInicio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (date != null) {
                    setState(() {
                      _dataInicio = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Color(0xFF6A1B9A)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data de Início',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_dataInicio),
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final valorParcela = _parseValor(_valorParcelaController.text);

              if (_totalParcelas > 0) {
                final valorTotal = valorParcela * _totalParcelas;

                // Gerar parcelas
                final parcelas = List.generate(_totalParcelas, (i) {
                  final dataVenc = DateTime(
                    _dataInicio.year,
                    _dataInicio.month + i,
                    _dataInicio.day,
                  );

                  // Status inicial baseado na data
                  StatusParcela status;
                  final hoje = DateTime.now();

                  if (dataVenc.isBefore(hoje)) {
                    status = StatusParcela.atrasada;
                  } else if (dataVenc.year == hoje.year &&
                      dataVenc.month == hoje.month) {
                    status = StatusParcela.aPagar;
                  } else {
                    status = StatusParcela.futura;
                  }

                  return Parcela(
                    numero: i + 1,
                    dataVencimento: dataVenc,
                    status: status,
                    valorPago: null, // Começa sem valor pago
                  );
                });

                final conta = ContaFixa(
                  nome: _nomeController.text,
                  valorTotal: valorTotal,
                  totalParcelas: _totalParcelas,
                  dataInicio: _dataInicio,
                  categoria: _categoriaController.text.isNotEmpty
                      ? _categoriaController.text
                      : null,
                  parcelas: parcelas,
                );

                widget.onSalvar(conta);
                Navigator.pop(context);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorParcelaController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
}
