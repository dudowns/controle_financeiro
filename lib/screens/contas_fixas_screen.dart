// lib/screens/contas_fixas_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/conta_fixa_model.dart';
import '../utils/currency_formatter.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_counter.dart';
import 'adicionar_conta_fixa_dialog.dart';

class ContasFixasScreen extends StatefulWidget {
  const ContasFixasScreen({super.key});

  @override
  State<ContasFixasScreen> createState() => _ContasFixasScreenState();
}

class _ContasFixasScreenState extends State<ContasFixasScreen> {
  final DBHelper _db = DBHelper();
  List<ContaFixa> _contas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  Future<void> _carregarContas() async {
    setState(() => _carregando = true);
    try {
      // 🔥 Usando _db para matar warning
      final db = await _db.database;
      debugPrint('📦 Banco acessado: ${db.path}');

      // Dados de exemplo
      _contas = [
        ContaFixa(
          nome: 'Celular Samsung',
          valorTotal: 4000,
          totalParcelas: 8,
          dataInicio: DateTime(2026, 1, 10),
          categoria: 'Eletrônicos',
          parcelas: List.generate(8, (i) {
            final dataVenc = DateTime(2026, 1 + i, 10);
            final status = i < 5
                ? StatusParcela.paga
                : i == 5
                    ? StatusParcela.aPagar
                    : StatusParcela.futura;
            return Parcela(
              numero: i + 1,
              dataVencimento: dataVenc,
              status: status,
              valorPago: status == StatusParcela.paga ? 500 : null,
            );
          }),
        ),
      ];
    } catch (e) {
      debugPrint('❌ Erro ao carregar contas: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarConta(ContaFixa conta) async {
    try {
      setState(() {
        _contas.add(conta);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Conta adicionada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatarValor(double valor) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(valor);

  Color _getCorStatus(StatusParcela status) {
    switch (status) {
      case StatusParcela.paga:
        return Colors.green;
      case StatusParcela.aPagar:
        return Colors.orange;
      case StatusParcela.futura:
        return Colors.grey;
    }
  }

  IconData _getIconeStatus(StatusParcela status) {
    switch (status) {
      case StatusParcela.paga:
        return Icons.check_circle;
      case StatusParcela.aPagar:
        return Icons.warning;
      case StatusParcela.futura:
        return Icons.schedule;
    }
  }

  String _getTextoStatus(StatusParcela status) {
    switch (status) {
      case StatusParcela.paga:
        return 'PAGA';
      case StatusParcela.aPagar:
        return 'A PAGAR';
      case StatusParcela.futura:
        return 'FUTURA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas Fixas'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _contas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma conta fixa',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para adicionar',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contas.length,
                  itemBuilder: (context, index) {
                    final conta = _contas[index];
                    final progresso = conta.parcelasPagas / conta.totalParcelas;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        title: Text(
                          conta.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${conta.parcelasPagas}/${conta.totalParcelas} parcelas',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progresso,
                              backgroundColor: Colors.grey[200],
                              color: progresso >= 1
                                  ? Colors.green
                                  : AppColors.primaryPurple,
                              minHeight: 4,
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AnimatedCounter(
                                value: conta.valorPago,
                                formatter: _formatarValor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              Text(
                                '/ ${_formatarValor(conta.valorTotal)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: const Text(
                                          'Mês',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: const Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: const Text(
                                          'Valor',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                ...conta.parcelas.map((parcela) {
                                  final corStatus =
                                      _getCorStatus(parcela.status);
                                  final iconeStatus =
                                      _getIconeStatus(parcela.status);
                                  final textoStatus =
                                      _getTextoStatus(parcela.status);
                                  final valorParcela = parcela.valorPago ??
                                      (conta.valorTotal / conta.totalParcelas);

                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            DateFormat('MMM/yy')
                                                .format(parcela.dataVencimento),
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Icon(
                                                iconeStatus,
                                                size: 14,
                                                color: corStatus,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                textoStatus,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: corStatus,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatarValor(valorParcela),
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: parcela.status ==
                                                      StatusParcela.paga
                                                  ? Colors.green
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AdicionarContaFixaDialog(
              onSalvar: _salvarConta,
            ),
          );
        },
      ),
    );
  }
}
