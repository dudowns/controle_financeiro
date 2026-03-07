// lib/screens/adicionar_investimento.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/gradient_button.dart';
import '../services/notification_service.dart';

class AdicionarInvestimentoScreen extends StatefulWidget {
  const AdicionarInvestimentoScreen({super.key});

  @override
  State<AdicionarInvestimentoScreen> createState() =>
      _AdicionarInvestimentoScreenState();
}

class _AdicionarInvestimentoScreenState
    extends State<AdicionarInvestimentoScreen> {
  final DBHelper db = DBHelper();

  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();

  String _tipoSelecionado = 'ACAO';
  DateTime _dataSelecionada = DateTime.now();

  final List<String> _tipos = ['ACAO', 'FII', 'ETF', 'BDR', 'CRIPTO'];

  @override
  void dispose() {
    _tickerController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  // 🔥 DATEPICKER SEM BUILDER PERSONALIZADO
  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      // ✅ SEM builder! Deixa o tema global do app cuidar disso
    );

    if (picked != null && mounted) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  Future<void> _salvar() async {
    if (_tickerController.text.isEmpty ||
        _quantidadeController.text.isEmpty ||
        _precoController.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preencha todos os campos!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      double quantidade =
          double.parse(_quantidadeController.text.replaceAll(',', '.'));
      double preco = double.parse(_precoController.text.replaceAll(',', '.'));

      await db.insertInvestimento({
        'ticker': _tickerController.text.toUpperCase(),
        'tipo': _tipoSelecionado,
        'quantidade': quantidade,
        'preco_medio': preco,
        'preco_atual': preco,
        'data_compra': _dataSelecionada.toIso8601String(),
      });

      await NotificationService().addNotification(
        titulo: '📈 Novo Investimento',
        mensagem:
            '${_tickerController.text.toUpperCase()} - $quantidade cotas a R\$ ${preco.toStringAsFixed(2)}',
        ticker: _tickerController.text.toUpperCase(),
        valor: preco,
      );

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ ${_tickerController.text.toUpperCase()} adicionado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Investimento'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novo Investimento',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Ticker
            TextField(
              controller: _tickerController,
              decoration: InputDecoration(
                labelText: 'Ticker',
                hintText: 'Ex: PETR4, MXRF11, BTC',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.tag),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Tipo
            DropdownButtonFormField<String>(
              initialValue: _tipoSelecionado,
              decoration: InputDecoration(
                labelText: 'Tipo de Ativo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _tipos.map((tipo) {
                String emoji;
                switch (tipo) {
                  case 'ACAO':
                    emoji = '📈';
                    break;
                  case 'FII':
                    emoji = '🏢';
                    break;
                  case 'ETF':
                    emoji = '📊';
                    break;
                  case 'BDR':
                    emoji = '🌎';
                    break;
                  case 'CRIPTO':
                    emoji = '🪙';
                    break;
                  default:
                    emoji = '';
                }
                return DropdownMenuItem(
                  value: tipo,
                  child: Text('$emoji $tipo'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoSelecionado = value!;
                });
              },
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Quantidade
            TextField(
              controller: _quantidadeController,
              decoration: InputDecoration(
                labelText: 'Quantidade de Cotas',
                hintText: 'Ex: 10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Preço
            TextField(
              controller: _precoController,
              decoration: InputDecoration(
                labelText: 'Preço por Cota',
                hintText: '5,00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSizes.paddingL),

            // 🔥 DATEPICKER SEM BUILDER
            InkWell(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primaryPurple),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data da Compra',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_dataSelecionada),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down,
                        color: AppColors.primaryPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),

            // Botão
            GradientButton(
              text: 'ADICIONAR INVESTIMENTO',
              icon: Icons.add,
              onPressed: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
