// lib/screens/contas_fixas_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/conta_fixa_model.dart';
import '../utils/currency_formatter.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_card.dart';
import 'adicionar_conta_fixa_dialog.dart';

class ContasFixasScreen extends StatefulWidget {
  const ContasFixasScreen({super.key});

  @override
  State<ContasFixasScreen> createState() => _ContasFixasScreenState();
}

class _ContasFixasScreenState extends State<ContasFixasScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final DBHelper _db = DBHelper();
  List<ContaFixa> _contas = [];
  bool _carregando = true;

  late AnimationController _animationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _carregarContas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarContas() async {
    setState(() => _carregando = true);
    try {
      debugPrint('🔍 Carregando contas fixas do banco...');
      final contasJson = await _db.getAllContasFixas();
      debugPrint('📊 Encontradas ${contasJson.length} contas no banco');

      List<ContaFixa> contasCarregadas = [];

      for (var contaJson in contasJson) {
        debugPrint(
            '   → Processando conta: ${contaJson['nome']} (ID: ${contaJson['id']})');

        final parcelasJson = await _db.getParcelasByContaId(contaJson['id']);
        debugPrint('      → Parcelas encontradas: ${parcelasJson.length}');

        final parcelas = parcelasJson.map((p) {
          return Parcela(
            numero: p['numero'],
            dataVencimento: DateTime.parse(p['data_vencimento']),
            status: StatusParcela.values[p['status']],
            dataPagamento: p['data_pagamento'] != null
                ? DateTime.parse(p['data_pagamento'])
                : null,
            valorPago: p['valor_pago']?.toDouble(),
          );
        }).toList();

        contasCarregadas.add(ContaFixa(
          id: contaJson['id'],
          nome: contaJson['nome'],
          valorTotal: contaJson['valor_total'].toDouble(),
          totalParcelas: contaJson['total_parcelas'],
          dataInicio: DateTime.parse(contaJson['data_inicio']),
          categoria: contaJson['categoria'],
          observacao: contaJson['observacao'],
          parcelas: parcelas,
        ));
      }

      debugPrint('✅ Total de contas carregadas: ${contasCarregadas.length}');
      _contas = contasCarregadas;
    } catch (e, stacktrace) {
      debugPrint('❌ ERRO AO CARREGAR CONTAS: $e');
      debugPrint('📍 Stacktrace: $stacktrace');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarConta(ContaFixa conta) async {
    try {
      debugPrint('🔍 Salvando conta: ${conta.nome}');
      debugPrint('   → Total parcelas: ${conta.totalParcelas}');
      debugPrint('   → Valor total: ${conta.valorTotal}');

      final id = await _db.insertContaFixa(conta);
      debugPrint('✅ Conta salva com ID: $id');

      await _carregarContas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
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
    } catch (e) {
      debugPrint('❌ ERRO AO SALVAR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleParcelaStatus(int contaIndex, int parcelaIndex) async {
    setState(() {
      final parcela = _contas[contaIndex].parcelas[parcelaIndex];
      final hoje = DateTime.now();

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
      } else {
        parcela.status = StatusParcela.paga;
        parcela.valorPago =
            _contas[contaIndex].valorTotal / _contas[contaIndex].totalParcelas;
      }
    });

    final conta = _contas[contaIndex];
    await _db.updateContaFixa(conta);
  }

  Future<void> _excluirConta(int index) async {
    final conta = _contas[index];
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: Text('Deseja realmente excluir "${conta.nome}"?'),
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
      await _db.deleteContaFixa(conta.id!);
      await _carregarContas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('🗑️ Conta excluída!')),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 9,
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
    super.build(context);

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
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _contas.isEmpty
              ? Center(
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
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _animationController,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: _contas.length,
                    itemBuilder: (context, index) {
                      final conta = _contas[index];

                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        curve: Curves.easeOutCubic,
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ModernCard(
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primaryPurple,
                                        AppColors.secondaryPurple,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  conta.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        conta.categoria ?? 'Sem categoria',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${conta.parcelasPagas}/${conta.totalParcelas}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      onPressed: () => _excluirConta(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _formatarValor(conta.valorPago),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primaryPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                  flex: 1, child: Text('')),
                                              const Expanded(
                                                flex: 2,
                                                child: Text('Data',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              const Expanded(
                                                flex: 2,
                                                child: Text('Status',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text('Valor',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    textAlign: TextAlign.right),
                                              ),
                                              const Expanded(
                                                  flex: 1, child: Text('')),
                                            ],
                                          ),
                                        ),
                                        ...conta.parcelas.map((parcela) {
                                          final corStatus =
                                              _getCorStatus(parcela.status);
                                          final valorParcela =
                                              parcela.valorPago ??
                                                  conta.valorTotal /
                                                      conta.totalParcelas;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: parcela.status ==
                                                      StatusParcela.atrasada
                                                  ? Colors.red.withOpacity(0.05)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color:
                                                    corStatus.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Transform.scale(
                                                    scale: 0.9,
                                                    child: Checkbox(
                                                      value: parcela.status ==
                                                          StatusParcela.paga,
                                                      onChanged: (_) =>
                                                          _toggleParcelaStatus(
                                                              index,
                                                              conta.parcelas
                                                                  .indexOf(
                                                                      parcela)),
                                                      activeColor: Colors.green,
                                                      checkColor: Colors.white,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    DateFormat('dd/MM').format(
                                                        parcela.dataVencimento),
                                                    style: const TextStyle(
                                                        fontSize: 12),
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
                                                        valorParcela),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: parcela.status ==
                                                              StatusParcela.paga
                                                          ? Colors.green
                                                          : parcela.status ==
                                                                  StatusParcela
                                                                      .atrasada
                                                              ? Colors.red[700]
                                                              : Colors
                                                                  .grey[800],
                                                    ),
                                                  ),
                                                ),
                                                const Expanded(
                                                    flex: 1, child: SizedBox()),
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AdicionarContaFixaDialog(
              onSalvar: _salvarConta,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
