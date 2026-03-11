// lib/screens/contas_fixas_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conta_fixa_model.dart';
import '../constants/app_colors.dart';
import '../database/db_helper.dart';
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
  bool _isLoading = true;
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _carregarContasDoBanco();
  }

  Future<void> _carregarContasDoBanco() async {
    setState(() => _isLoading = true);
    try {
      final contasJson = await _dbHelper.getAllContasFixas();
      List<ContaFixa> contas = [];

      for (var contaJson in contasJson) {
        // 🔥 CARREGAR TODAS AS PARCELAS DA CONTA
        final parcelasJson =
            await _dbHelper.getParcelasByContaId(contaJson['id']);

        debugPrint(
            '📊 Conta ${contaJson['nome']}: ${parcelasJson.length} parcelas carregadas');

        final parcelas = parcelasJson.map((p) {
          final status = StatusParcela.values[p['status']];
          return Parcela(
            numero: p['numero'],
            dataVencimento: DateTime.parse(p['data_vencimento']),
            status: status,
            valorPago: p['valor_pago']?.toDouble(),
            dataPagamento: p['data_pagamento'] != null
                ? DateTime.parse(p['data_pagamento'])
                : null,
          );
        }).toList();

        contas.add(ContaFixa(
          id: contaJson['id'],
          nome: contaJson['nome'],
          valorTotal: contaJson['valor_total'],
          totalParcelas: contaJson['total_parcelas'],
          dataInicio: DateTime.parse(contaJson['data_inicio']),
          categoria: contaJson['categoria'],
          observacao: contaJson['observacao'],
          parcelas: parcelas, // 🔥 TODAS AS PARCELAS AQUI!
        ));
      }

      setState(() {
        _contas = contas;
        _isLoading = false;
      });

      debugPrint('✅ Total de ${_contas.length} contas carregadas');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Erro ao carregar contas: $e');
      _mostrarSnackbar('Erro ao carregar contas', isErro: true);
    }
  }

  void _mostrarSnackbar(String mensagem, {bool isErro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _salvarConta(ContaFixa conta) async {
    try {
      final id = await _dbHelper.insertContaFixa(conta);
      conta.id = id;
      setState(() => _contas.add(conta));
      _mostrarSnackbar('✅ Conta adicionada!');
    } catch (e) {
      _mostrarSnackbar('Erro ao salvar: $e', isErro: true);
    }
  }

  Future<void> _editarConta(ContaFixa conta, int index) async {
    final result = await showDialog<ContaFixa>(
      context: context,
      builder: (_) => EditarContaFixaDialog(conta: conta),
    );
    if (result != null) {
      try {
        await _dbHelper.updateContaFixa(result);
        setState(() => _contas[index] = result);
        _mostrarSnackbar('✅ Conta atualizada!');
      } catch (e) {
        _mostrarSnackbar('Erro ao atualizar: $e', isErro: true);
      }
    }
  }

  Future<void> _toggleParcelaStatus(int contaIndex, int parcelaIndex) async {
    final conta = _contas[contaIndex];
    final parcela = conta.parcelas[parcelaIndex];
    final hoje = DateTime.now();

    setState(() {
      if (parcela.status == StatusParcela.paga) {
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
        parcela.status = StatusParcela.paga;
        parcela.valorPago = conta.valorTotal / conta.totalParcelas;
        parcela.dataPagamento = hoje;
      }
    });

    try {
      await _dbHelper.updateContaFixa(conta);
    } catch (e) {
      _mostrarSnackbar('Erro ao salvar status', isErro: true);
    }
  }

  void _excluirConta(int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: Text('Deseja excluir "${_contas[index].nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _dbHelper.deleteContaFixa(_contas[index].id!);
        setState(() => _contas.removeAt(index));
        _mostrarSnackbar('🗑️ Conta excluída!');
      } catch (e) {
        _mostrarSnackbar('Erro ao excluir: $e', isErro: true);
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
      case StatusParcela.atrasada:
        return Colors.red;
      case StatusParcela.futura:
        return Colors.grey;
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
    final texto = _getTextoStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 9, color: cor, fontWeight: FontWeight.bold),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _contas.length,
                  itemBuilder: (context, index) {
                    final conta = _contas[index];
                    final progresso = conta.parcelasPagas / conta.totalParcelas;
                    final valorParcela = conta.valorTotal / conta.totalParcelas;
                    final isExpanded = _expandedIndex == index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ModernCard(
                        child: Column(
                          children: [
                            _buildCabecalhoCompacto(
                              conta,
                              index,
                              progresso,
                              valorParcela,
                              isExpanded,
                            ),
                            if (isExpanded)
                              _buildDetalhesCompacto(
                                  conta, index, valorParcela),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AdicionarContaFixaDialog(onSalvar: _salvarConta),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Nenhuma conta fixa', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Toque no + para adicionar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoCompacto(
    ContaFixa conta,
    int index,
    double progresso,
    double valorParcela,
    bool isExpanded,
  ) {
    return InkWell(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ícone
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                conta.categoria == 'Empréstimo'
                    ? Icons.attach_money
                    : Icons.shopping_bag,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e categoria
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conta.nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          conta.categoria ?? 'Outros',
                          style: TextStyle(
                              fontSize: 8, color: AppColors.primaryPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Progresso
                  Row(
                    children: [
                      Text(
                        '${conta.parcelasPagas}/${conta.totalParcelas}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progresso.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: progresso >= 1
                                ? Colors.green
                                : AppColors.primaryPurple,
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Valores
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCounter(
                    value: conta.valorPago,
                    formatter: _formatarValor,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  Text(
                    '/ ${_formatarValor(conta.valorTotal)}',
                    style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Seta
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesCompacto(
      ContaFixa conta, int index, double valorParcela) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                color: AppColors.primaryPurple,
                onPressed: () => _editarConta(conta, index),
                constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                padding: EdgeInsets.zero,
                splashRadius: 20,
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                color: Colors.red,
                onPressed: () => _excluirConta(index),
                constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                padding: EdgeInsets.zero,
                splashRadius: 20,
                tooltip: 'Excluir',
              ),
            ],
          ),

          // Cabeçalho da tabela
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Vencimento',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700]),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Valor',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700]),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // 🔥 TODAS AS PARCELAS - MOSTRANDO TODAS AS QUE EXISTEM NO BANCO
          if (conta.parcelas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Nenhuma parcela encontrada',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            )
          else
            ...conta.parcelas.asMap().entries.map((entry) {
              final i = entry.key;
              final parcela = entry.value;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: parcela.status == StatusParcela.atrasada
                      ? Colors.red.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Checkbox
                    Expanded(
                      flex: 1,
                      child: Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: parcela.status == StatusParcela.paga,
                          onChanged: (_) => _toggleParcelaStatus(index, i),
                          activeColor: Colors.green,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    // Data
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('dd/MM/yy').format(parcela.dataVencimento),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: parcela.status == StatusParcela.atrasada
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Status
                    Expanded(
                      flex: 2,
                      child: _buildStatusBadge(parcela.status),
                    ),
                    // Valor
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatarValor(parcela.valorPago ?? valorParcela),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: parcela.status == StatusParcela.paga
                              ? Colors.green
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          // 🔥 MOSTRAR TOTAL DE PARCELAS
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Total: ${conta.parcelas.length} parcelas',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
