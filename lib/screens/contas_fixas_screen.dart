// lib/screens/contas_fixas_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/conta_fixa_model.dart';
import '../utils/currency_formatter.dart';
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

class _ContasFixasScreenState extends State<ContasFixasScreen>
    with TickerProviderStateMixin {
  final DBHelper _db = DBHelper();
  List<ContaFixa> _contas = [];
  bool _carregando = true;

  late AnimationController _animationController;

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
      final db = await _db.database;
      debugPrint('📦 Banco acessado: ${db.path}');

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

  Future<void> _salvarConta(ContaFixa conta) async {
    try {
      setState(() {
        _contas.add(conta);
      });
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

  void _toggleParcelaStatus(int contaIndex, int parcelaIndex) {
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
  }

  Future<void> _editarParcela(int contaIndex, int parcelaIndex) async {
    final parcela = _contas[contaIndex].parcelas[parcelaIndex];
    final valorOriginal =
        _contas[contaIndex].valorTotal / _contas[contaIndex].totalParcelas;

    final TextEditingController valorController = TextEditingController(
      text: (parcela.valorPago ?? valorOriginal)
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );

    bool pago = parcela.status == StatusParcela.paga;
    DateTime? dataPagamento = parcela.dataPagamento ?? DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Editar Parcela ${parcela.numero}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor da Parcela (R\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('Pago?'),
                      const Spacer(),
                      Switch(
                        value: pago,
                        onChanged: (value) {
                          setStateDialog(() {
                            pago = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text(
                        pago ? 'SIM' : 'NÃO',
                        style: TextStyle(
                          color: pago ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pago) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dataPagamento!,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (date != null) {
                        setStateDialog(() {
                          dataPagamento = date;
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
                                'Data de Pagamento',
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(dataPagamento!),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    final novoValor =
                        double.parse(valorController.text.replaceAll(',', '.'));

                    Navigator.pop(context, {
                      'valor': novoValor,
                      'pago': pago,
                      'dataPagamento': dataPagamento,
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Valor inválido!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                ),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        final novoValor = result['valor'] as double;
        final pago = result['pago'] as bool;
        final dataPagamento = result['dataPagamento'] as DateTime;

        _contas[contaIndex].parcelas[parcelaIndex].valorPago = novoValor;
        _contas[contaIndex].parcelas[parcelaIndex].status =
            pago ? StatusParcela.paga : StatusParcela.atrasada;
        _contas[contaIndex].parcelas[parcelaIndex].dataPagamento =
            pago ? dataPagamento : null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('✅ Parcela atualizada!')),
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

    valorController.dispose();
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
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('✅ Conta atualizada!')),
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

  Future<void> _excluirConta(int index) async {
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
      });

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_contas.isEmpty) {
            return Center(
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
                    const SizedBox(height: 100), // 🔥 ESPAÇO PARA O BOTÃO
                  ],
                ),
              ),
            );
          }

          return FadeTransition(
            opacity: _animationController,
            child: ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 120), // 🔥 MAIS ESPAÇO!
              itemCount: _contas.length,
              itemBuilder: (context, index) {
                final conta = _contas[index];
                final progresso = conta.parcelasPagas / conta.totalParcelas;
                final valorParcela = conta.valorTotal / conta.totalParcelas;

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
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryPurple.withOpacity(0.3),
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
                          title: Text(
                            conta.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryPurple
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      conta.categoria ?? 'Sem categoria',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primaryPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${conta.parcelasPagas}/${conta.totalParcelas} parcelas',
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
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    height: 8,
                                    width: MediaQuery.of(context).size.width *
                                        0.6 *
                                        progresso,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: progresso >= 1
                                            ? [Colors.green, Colors.green]
                                            : [
                                                AppColors.primaryPurple,
                                                AppColors.secondaryPurple
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: progresso >= 1
                                              ? Colors.green.withOpacity(0.3)
                                              : AppColors.primaryPurple
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botões de editar/excluir
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppColors.primaryPurple,
                                ),
                                onPressed: () => _editarConta(conta, index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _excluirConta(index),
                              ),
                              // Container com os valores
                              Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatarValor(conta.valorPago),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.primaryPurple,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '/ ${_formatarValor(conta.valorTotal)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
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
                                          child: const Row(
                                            children: [
                                              // Já temos os botões no trailing
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Container(),
                                        ),
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
                                          color: corStatus.withOpacity(0.3),
                                        ),
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
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatarValor(
                                                      parcela.valorPago ??
                                                          valorParcela),
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
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_note,
                                                    size: 18,
                                                    color:
                                                        AppColors.primaryPurple,
                                                  ),
                                                  onPressed: () =>
                                                      _editarParcela(index, i),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
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
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryPurple,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nova Conta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
