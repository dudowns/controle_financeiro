// lib/screens/adicionar_conta_fixa_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conta_fixa_model.dart';
import '../constants/app_colors.dart';

class AdicionarContaFixaDialog extends StatefulWidget {
  final Function(ContaFixa) onSalvar;

  const AdicionarContaFixaDialog({
    super.key,
    required this.onSalvar,
  });

  @override
  State<AdicionarContaFixaDialog> createState() =>
      _AdicionarContaFixaDialogState();
}

class _AdicionarContaFixaDialogState extends State<AdicionarContaFixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorParcelaController =
      TextEditingController(); // 🔹 VALOR DA PARCELA
  final _parcelasController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _observacaoController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  String? _categoriaSelecionada;

  double _valorTotal = 0; // 🔹 VALOR TOTAL CALCULADO

  final List<String> _categorias = [
    'Empréstimo',
    'Eletrônicos',
    'Educação',
    'Saúde',
    'Lazer',
    'Vestuário',
    'Alimentação',
    'Transporte',
    'Outros',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _valorParcelaController.dispose();
    _parcelasController.dispose();
    _categoriaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // 🔹 CALCULAR VALOR TOTAL QUANDO PARCELA OU NÚMERO DE PARCELAS MUDAR
  void _calcularValorTotal() {
    final valorParcelaText = _valorParcelaController.text;
    final parcelasText = _parcelasController.text;

    if (valorParcelaText.isNotEmpty && parcelasText.isNotEmpty) {
      final valorParcela = double.tryParse(valorParcelaText) ?? 0;
      final parcelas = int.tryParse(parcelasText) ?? 0;

      setState(() {
        _valorTotal = valorParcela * parcelas;
      });
    } else {
      setState(() {
        _valorTotal = 0;
      });
    }
  }

  List<Parcela> _gerarParcelas() {
    final totalParcelas = int.parse(_parcelasController.text);
    final valorParcela = double.parse(
        _valorParcelaController.text); // 🔹 USA O VALOR DA PARCELA DIGITADO
    final List<Parcela> parcelas = [];

    for (int i = 0; i < totalParcelas; i++) {
      final dataVencimento = DateTime(
        _dataInicio.year,
        _dataInicio.month + i,
        _dataInicio.day,
      );

      StatusParcela status;
      DateTime? dataPagamento;

      if (dataVencimento.isBefore(DateTime.now())) {
        status = StatusParcela.atrasada;
      } else if (dataVencimento.month == DateTime.now().month &&
          dataVencimento.year == DateTime.now().year) {
        status = StatusParcela.aPagar;
      } else {
        status = StatusParcela.futura;
      }

      if (status == StatusParcela.paga) {
        dataPagamento = DateTime.now();
      }

      parcelas.add(
        Parcela(
          numero: i + 1,
          dataVencimento: dataVencimento,
          status: status,
          valorPago: status == StatusParcela.paga ? valorParcela : null,
          dataPagamento: dataPagamento,
        ),
      );
    }

    return parcelas;
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valorParcela = double.parse(_valorParcelaController.text);
      final totalParcelas = int.parse(_parcelasController.text);

      final conta = ContaFixa(
        nome: _nomeController.text,
        valorTotal: valorParcela * totalParcelas, // 🔹 CALCULA VALOR TOTAL
        totalParcelas: totalParcelas,
        dataInicio: _dataInicio,
        categoria: _categoriaSelecionada ?? _categoriaController.text,
        observacao: _observacaoController.text.isNotEmpty
            ? _observacaoController.text
            : null,
        parcelas: _gerarParcelas(),
      );

      widget.onSalvar(conta);
      Navigator.pop(context);
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _dataInicio) {
      setState(() {
        _dataInicio = picked;
      });
    }
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F5F5)],
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nova Conta Fixa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome da conta',
                    prefixIcon: const Icon(Icons.shopping_bag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔹 VALOR DA PARCELA E NÚMERO DE PARCELAS
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valorParcelaController,
                        decoration: InputDecoration(
                          labelText: 'Valor da parcela',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _calcularValorTotal(), // 🔹 CALCULA TOTAL
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Obrigatório';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _parcelasController,
                        decoration: InputDecoration(
                          labelText: 'Nº de parcelas',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _calcularValorTotal(), // 🔹 CALCULA TOTAL
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Obrigatório';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                // 🔹 MOSTRAR VALOR TOTAL CALCULADO
                if (_valorTotal > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          size: 20,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Valor total: ${_formatarValor(_valorTotal)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Data de início
                InkWell(
                  onTap: _selecionarData,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data de início',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_dataInicio),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Categoria
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Selecione ou digite'),
                          ),
                          ..._categorias.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _categoriaSelecionada = value;
                          });
                        },
                      ),
                    ),
                    if (_categoriaSelecionada == null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _categoriaController,
                          decoration: InputDecoration(
                            labelText: 'Nova categoria',
                            prefixIcon: const Icon(Icons.add),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Observação
                TextFormField(
                  controller: _observacaoController,
                  decoration: InputDecoration(
                    labelText: 'Observação (opcional)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
