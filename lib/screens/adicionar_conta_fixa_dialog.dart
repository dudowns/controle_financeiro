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
  final _valorController = TextEditingController();
  final _categoriaController = TextEditingController();

  late DateTime _dataInicio;
  late int _totalParcelas;
  late double _valorParcelaCalculado;

  @override
  void initState() {
    super.initState();
    _dataInicio = DateTime.now();
    _totalParcelas = 1;
    _valorParcelaCalculado = 0;
  }

  double _parseValor(String texto) {
    try {
      return double.parse(texto.replaceAll(',', '.'));
    } catch (e) {
      return 0;
    }
  }

  void _atualizarValorParcela() {
    final valorTotal = _parseValor(_valorController.text);
    if (_totalParcelas > 0) {
      setState(() {
        _valorParcelaCalculado =
            valorTotal > 0 ? valorTotal / _totalParcelas : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Conta Fixa'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Conta',
                  hintText: 'Ex: Celular Samsung',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Valor total
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor Total (R\$)',
                  hintText: '4.000,00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _atualizarValorParcela(),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Campo obrigatório';
                  if (_parseValor(v!) <= 0)
                    return 'Valor deve ser maior que zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Total de parcelas
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _totalParcelas.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Total de Parcelas',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        setState(() {
                          _totalParcelas = int.tryParse(v) ?? 1;
                          _atualizarValorParcela();
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
                        labelText: 'Valor Parcela',
                        border: const OutlineInputBorder(),
                        hintText: _valorParcelaCalculado > 0
                            ? CurrencyFormatter.format(_valorParcelaCalculado)
                            : 'R\$ 0,00',
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
                ),
              ),
              const SizedBox(height: 12),

              // Data de início
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
                      const Icon(Icons.calendar_today, size: 16),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final valorTotal = _parseValor(_valorController.text);

              if (_totalParcelas > 0) {
                // 🔥 AGORA A VARIÁVEL É USADA!
                final valorParcela = valorTotal / _totalParcelas;

                // Usando a variável para mostrar no console (só pra não dar warning)
                debugPrint('📊 Valor da parcela: $valorParcela');

                // Gerar parcelas
                final parcelas = List.generate(_totalParcelas, (i) {
                  final dataVenc = DateTime(
                    _dataInicio.year,
                    _dataInicio.month + i,
                    _dataInicio.day,
                  );
                  return Parcela(
                    numero: i + 1,
                    dataVencimento: dataVenc,
                    status:
                        i == 0 ? StatusParcela.aPagar : StatusParcela.futura,
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
          ),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
}
