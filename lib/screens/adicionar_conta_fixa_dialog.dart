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
  final _valorParcelaController = TextEditingController();
  final _parcelasController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _observacaoController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  String? _categoriaSelecionada;
  double _valorTotal = 0;

  final List<String> _categorias = const [
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

  // 🔹 FUNÇÃO PARA CONVERTER VÍRGULA PARA PONTO
  String _formatarValorParaDouble(String valor) {
    return valor.replaceAll(',', '.');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorParcelaController.dispose();
    _parcelasController.dispose();
    _categoriaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _calcularValorTotal() {
    final valorParcelaText =
        _formatarValorParaDouble(_valorParcelaController.text);
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
    final totalParcelas = int.tryParse(_parcelasController.text) ?? 0;
    final valorParcela = double.tryParse(
            _formatarValorParaDouble(_valorParcelaController.text)) ??
        0;

    if (totalParcelas <= 0 || valorParcela <= 0) {
      return [];
    }

    final List<Parcela> parcelas = [];

    for (int i = 0; i < totalParcelas; i++) {
      final dataVencimento = DateTime(
        _dataInicio.year,
        _dataInicio.month + i,
        _dataInicio.day,
      );

      StatusParcela status;

      if (dataVencimento.isBefore(DateTime.now())) {
        status = StatusParcela.atrasada;
      } else if (dataVencimento.month == DateTime.now().month &&
          dataVencimento.year == DateTime.now().year) {
        status = StatusParcela.aPagar;
      } else {
        status = StatusParcela.futura;
      }

      parcelas.add(
        Parcela(
          numero: i + 1,
          dataVencimento: dataVencimento,
          status: status,
          valorPago: null,
          dataPagamento: null,
        ),
      );
    }

    return parcelas;
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valorParcela = double.tryParse(
              _formatarValorParaDouble(_valorParcelaController.text)) ??
          0;
      final totalParcelas = int.tryParse(_parcelasController.text) ?? 0;

      if (valorParcela <= 0 || totalParcelas <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valores inválidos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final conta = ContaFixa(
        nome: _nomeController.text,
        valorTotal: valorParcela * totalParcelas,
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

                // Valor da parcela e número de parcelas
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
                        onChanged: (value) => _calcularValorTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Obrigatório';
                          }
                          // 🔹 ACEITA VÍRGULA NA VALIDAÇÃO
                          final valorFormatado = value.replaceAll(',', '.');
                          if (double.tryParse(valorFormatado) == null) {
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
                        onChanged: (value) => _calcularValorTotal(),
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

                // Mostrar valor total calculado
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
                            child: Text('Selecione'),
                          ),
                          ..._categorias
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _categoriaSelecionada = value;
                          });
                        },
                      ),
                    ),
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
