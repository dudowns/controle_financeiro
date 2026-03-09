// lib/screens/contas_fixas_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conta_fixa_model.dart';
import '../constants/app_colors.dart';
import '../widgets/animated_counter.dart';
import '../widgets/modern_card.dart';
import 'adicionar_conta_fixa_dialog.dart';
import 'editar_conta_fixa_dialog.dart';

class ContasFixasScreen extends StatefulWidget {
  const ContasFixasScreen({super.key});

  @override
  State<ContasFixasScreen> createState() => _ContasFixasScreenState();
}

class _ContasFixasScreenState extends State<ContasFixasScreen> {
  List<ContaFixa> _contas = [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  void _carregarContas() {
    // Dados de exemplo
    setState(() {
      _contas = [
        ContaFixa(
          nome: 'Celular Samsung',
          valorTotal: 4000,
          totalParcelas: 8,
          dataInicio: DateTime(2026, 1, 10),
          categoria: 'Eletrônicos',
          parcelas: List.generate(8, (i) {
            final dataVenc = DateTime(2026, 1 + i, 10);
            final status = _getStatusInicial(dataVenc);
            return Parcela(
              numero: i + 1,
              dataVencimento: dataVenc,
              status: status,
              valorPago: status == StatusParcela.paga ? 500 : null,
              dataPagamento:
                  status == StatusParcela.paga ? DateTime.now() : null,
            );
          }),
        ),
        ContaFixa(
          nome: 'Curso de Flutter',
          valorTotal: 1500,
          totalParcelas: 6,
          dataInicio: DateTime(2026, 2, 5),
          categoria: 'Educação',
          parcelas: List.generate(6, (i) {
            final dataVenc = DateTime(2026, 2 + i, 5);
            final status = _getStatusInicial(dataVenc);
            return Parcela(
              numero: i + 1,
              dataVencimento: dataVenc,
              status: status,
              valorPago: status == StatusParcela.paga ? 250 : null,
              dataPagamento:
                  status == StatusParcela.paga ? DateTime.now() : null,
            );
          }),
        ),
      ];
    });
  }

  StatusParcela _getStatusInicial(DateTime dataVencimento) {
    final hoje = DateTime.now();
    if (dataVencimento.isBefore(hoje)) {
      return StatusParcela.atrasada;
    } else if (dataVencimento.year == hoje.year &&
        dataVencimento.month == hoje.month) {
      return StatusParcela.aPagar;
    } else {
      return StatusParcela.futura;
    }
  }

  void _salvarConta(ContaFixa conta) {
    setState(() {
      _contas.add(conta);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('✅ Conta adicionada com sucesso!')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _editarConta(ContaFixa conta, int index) async {
    final result = await showDialog<ContaFixa>(
      context: context,
      builder: (_) => EditarContaFixaDialog(conta: conta),
    );

    if (result != null) {
      setState(() {
        _contas[index] = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('✅ Conta atualizada com sucesso!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _toggleParcelaStatus(int contaIndex, int parcelaIndex) {
    setState(() {
      final parcela = _contas[contaIndex].parcelas[parcelaIndex];
      final hoje = DateTime.now();

      if (parcela.status == StatusParcela.paga) {
        // Desmarcar como paga
        if (parcela.dataVencimento.isBefore(hoje)) {
          parcela.status = StatusParcela.atrasada;
        } else if (parcela.dataVencimento.year == hoje.year &&
            parcela.dataVencimento.month == hoje.month) {
          parcela.status = StatusParcela.aPagar;
        } else {
          parcela.status = StatusParcela.futura;
        }
        parcela.valorPago = null;
        parcela.dataPagamento = null;
      } else {
        // Marcar como paga
        parcela.status = StatusParcela.paga;
        parcela.valorPago =
            _contas[contaIndex].valorTotal / _contas[contaIndex].totalParcelas;
        parcela.dataPagamento = DateTime.now();
      }
    });
  }

  void _excluirConta(int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: Text('Deseja realmente excluir "${_contas[index].nome}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _contas.removeAt(index);
        if (_expandedIndex == index) {
          _expandedIndex = null;
        } else if (_expandedIndex != null && _expandedIndex! > index) {
          _expandedIndex = _expandedIndex! - 1;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('🗑️ Conta excluída!')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
      case StatusParcela.atrasada:
        return Colors.red;
      case StatusParcela.futura:
        return Colors.grey;
    }
  }

  IconData _getIconeStatus(StatusParcela status) {
    switch (status) {
      case StatusParcela.paga:
        return Icons.check_circle;
      case StatusParcela.aPagar:
        return Icons.warning_amber;
      case StatusParcela.atrasada:
        return Icons.error;
      case StatusParcela.futura:
        return Icons.access_time;
    }
  }

  String _getTextoStatus(StatusParcela status) {
    switch (status) {
      case StatusParcela.paga:
        return 'PAGA';
      case StatusParcela.aPagar:
        return 'A PAGAR';
      case StatusParcela.atrasada:
        return 'ATRASADA';
      case StatusParcela.futura:
        return 'FUTURA';
    }
  }

  Widget _buildStatusBadge(StatusParcela status) {
    final cor = _getCorStatus(status);
    final icone = _getIconeStatus(status);
    final texto = _getTextoStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: cor),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              color: cor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas Fixas'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _contas.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.primaryPurple.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Nenhuma conta fixa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para adicionar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 100),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 100,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _contas.length,
                itemBuilder: (context, index) {
                  final conta = _contas[index];
                  final progresso = conta.parcelasPagas / conta.totalParcelas;
                  final valorParcela = conta.valorTotal / conta.totalParcelas;
                  final isExpanded = _expandedIndex == index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ModernCard(
                      child: Column(
                        children: [
                          // Cabeçalho do card
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryPurple,
                                          AppColors.secondaryPurple,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryPurple
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          conta.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryPurple
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                conta.categoria ??
                                                    'Sem categoria',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.primaryPurple,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${conta.parcelasPagas}/${conta.totalParcelas}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Stack(
                                          children: [
                                            Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              height: 8,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.4 *
                                                  progresso,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: progresso >= 1
                                                      ? [
                                                          Colors.green,
                                                          Colors.green
                                                        ]
                                                      : [
                                                          AppColors
                                                              .primaryPurple,
                                                          AppColors
                                                              .secondaryPurple
                                                        ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: progresso >= 1
                                                        ? Colors.green
                                                            .withOpacity(0.3)
                                                        : AppColors
                                                            .primaryPurple
                                                            .withOpacity(0.3),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPurple
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
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
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Conteúdo expandido
                          if (isExpanded)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 18),
                                                color: AppColors.primaryPurple,
                                                onPressed: () =>
                                                    _editarConta(conta, index),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 24,
                                                color: Colors.grey[300],
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 18),
                                                color: Colors.red,
                                                onPressed: () =>
                                                    _excluirConta(index),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Cabeçalho da tabela
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 1, child: Container()),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Vencimento',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Valor',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ...conta.parcelas
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final i = entry.key;
                                    final parcela = entry.value;
                                    final corStatus =
                                        _getCorStatus(parcela.status);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: parcela.status ==
                                                StatusParcela.atrasada
                                            ? Colors.red.withOpacity(0.05)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: corStatus.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Transform.scale(
                                              scale: 1.2,
                                              child: Checkbox(
                                                value: parcela.status ==
                                                    StatusParcela.paga,
                                                onChanged: (_) =>
                                                    _toggleParcelaStatus(
                                                        index, i),
                                                activeColor: Colors.green,
                                                checkColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              DateFormat('dd/MM/yy').format(
                                                  parcela.dataVencimento),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: parcela.status ==
                                                        StatusParcela.atrasada
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: parcela.status ==
                                                        StatusParcela.atrasada
                                                    ? Colors.red[700]
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: _buildStatusBadge(
                                                parcela.status),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              _formatarValor(
                                                  parcela.valorPago ??
                                                      valorParcela),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: parcela.status ==
                                                        StatusParcela.paga
                                                    ? Colors.green
                                                    : parcela.status ==
                                                            StatusParcela
                                                                .atrasada
                                                        ? Colors.red[700]
                                                        : Colors.grey[800],
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
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
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
