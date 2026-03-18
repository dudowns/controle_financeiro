// lib/screens/contas_do_mes_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/pagamento_model.dart';
import '../constants/app_colors.dart';
import 'adicionar_conta_screen.dart';

class ContasDoMesScreen extends StatefulWidget {
  const ContasDoMesScreen({super.key});

  @override
  State<ContasDoMesScreen> createState() => _ContasDoMesScreenState();
}

class _ContasDoMesScreenState extends State<ContasDoMesScreen> {
  final DBHelper _dbHelper = DBHelper();
  DateTime _mesSelecionado = DateTime.now();
  List<PagamentoMes> _pagamentos = [];
  Map<String, dynamic> _resumo = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final pagamentosJson = await _dbHelper.getPagamentosDoMes(
        _mesSelecionado.year,
        _mesSelecionado.month,
      );
      _pagamentos =
          pagamentosJson.map((p) => PagamentoMes.fromJson(p)).toList();
      _resumo = await _dbHelper.getResumoContasDoMes(
        _mesSelecionado.year,
        _mesSelecionado.month,
      );
      setState(() => _carregando = false);
    } catch (e) {
      debugPrint('Erro: $e');
      setState(() => _carregando = false);
    }
  }

  String _formatarValor(double valor) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(valor);

  void _navegarMes(int delta) {
    setState(() => _mesSelecionado = DateTime(
          _mesSelecionado.year,
          _mesSelecionado.month + delta,
          1,
        ));
    _carregarDados();
  }

  Future<void> _pagarConta(PagamentoMes pagamento) async {
    final sucesso = await _dbHelper.pagarConta(pagamento.id!);
    if (sucesso && mounted) {
      _carregarDados();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${pagamento.contaNome} paga!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _excluirConta(int contaId, String nomeConta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: Text(
            'Deseja realmente excluir a conta "$nomeConta"?\n\nTodos os pagamentos futuros serão removidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _dbHelper.deletarConta(contaId);
        if (mounted) {
          _carregarDados();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🗑️ Conta "$nomeConta" excluída!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          'Contas do Mês',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),

                // Seletor de mês compacto
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 18),
                          onPressed: () => _navegarMes(-1),
                          color: AppColors.primary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', 'pt_BR')
                              .format(_mesSelecionado)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 18),
                          onPressed: () => _navegarMes(1),
                          color: AppColors.primary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cards de resumo
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildResumoCardAPagar(),
                      const SizedBox(width: 12),
                      _buildResumoCardPago(),
                    ],
                  ),
                ),

                // Lista de contas
                Expanded(
                  child: _pagamentos.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _pagamentos.length,
                          itemBuilder: (context, index) =>
                              _buildContaCardCompacto(_pagamentos[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
        onPressed: () async {
          if (await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdicionarContaScreen())) ==
              true) {
            _carregarDados();
          }
        },
      ),
    );
  }

  Widget _buildResumoCardAPagar() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A PAGAR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatarValor(_resumo['totalPendente'] ?? 0),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_resumo['qtdPendente'] ?? 0} ${_resumo['qtdPendente'] == 1 ? 'conta' : 'contas'}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCardPago() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAGO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatarValor(_resumo['totalPago'] ?? 0),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_resumo['qtdPago'] ?? 0} ${_resumo['qtdPago'] == 1 ? 'conta' : 'contas'}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card de conta compacto com botão de excluir
  Widget _buildContaCardCompacto(PagamentoMes pagamento) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _dbHelper.database.then((db) => db.query('contas',
              where: 'id = ?',
              whereArgs: [
                pagamento.contaId
              ]).then((r) => r.isNotEmpty ? r.first : null)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 70, child: Center(child: CircularProgressIndicator()));
        }

        // 🔥 VARIÁVEIS CORRIGIDAS - todas usadas!
        final contaData = snapshot.data;
        final categoria = contaData?['categoria'] as String? ?? 'Outros';
        final totalParcelas = contaData?['parcelas_total'] as int?;

        // Estas variáveis agora são usadas nos cálculos abaixo
        final dataInicio = contaData != null
            ? DateTime.tryParse(contaData['data_inicio'] as String? ?? '')
            : null;
        final tipo = contaData?['tipo'] as String? ?? 'mensal';

        String? infoParcela;
        int? parcelasRestantes;

        // Calcular parcelas usando as variáveis declaradas
        if (contaData != null && dataInicio != null) {
          try {
            final ehParcelada = tipo == 'parcelada' ||
                (totalParcelas != null && totalParcelas > 0);

            if (ehParcelada && totalParcelas != null && totalParcelas > 0) {
              final mesInicio = dataInicio.year * 100 + dataInicio.month;
              final mesAtual = pagamento.anoMes;

              if (mesAtual >= mesInicio) {
                final parcelaAtual = (mesAtual - mesInicio) + 1;
                if (parcelaAtual <= totalParcelas) {
                  infoParcela = '$parcelaAtual/$totalParcelas';
                  parcelasRestantes = totalParcelas - parcelaAtual;
                }
              }
            }
          } catch (e) {
            // Ignora erro no cálculo
          }
        }

        final atrasado = pagamento.estaAtrasado && !pagamento.estaPago;
        final Color corCategoria = AppColors.getCategoryColor(categoria);
        final cor = pagamento.estaPago
            ? AppColors.success
            : (atrasado ? AppColors.error : corCategoria);
        final corFundo = pagamento.estaPago
            ? AppColors.successLight
            : (atrasado ? AppColors.errorLight : corCategoria.withOpacity(0.1));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: corFundo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  pagamento.estaPago
                      ? Icons.check_circle
                      : (atrasado ? Icons.warning_amber : Icons.receipt),
                  color: cor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Informações
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pagamento.contaNome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: corCategoria,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          categoria,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (infoParcela != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              infoParcela,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vence ${pagamento.dataVencimentoFormatada}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Parcelas restantes
                    if (parcelasRestantes != null && parcelasRestantes > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Faltam $parcelasRestantes',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Valor e ações
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatarValor(pagamento.valor),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!pagamento.estaPago)
                        SizedBox(
                          width: 60,
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () => _pagarConta(pagamento),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                              minimumSize: const Size(60, 28),
                            ),
                            child: const Text(
                              'PAGAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // 🔥 BOTÃO DE EXCLUIR FUNCIONAL!
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        color: Colors.red[300],
                        onPressed: () => _excluirConta(
                            pagamento.contaId, pagamento.contaNome),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_outlined, size: 56, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Nenhuma conta para este mês',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              if (await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdicionarContaScreen())) ==
                  true) {
                _carregarDados();
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'ADICIONAR CONTA',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
