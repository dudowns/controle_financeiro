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
  DateTime _mesSelecionado = DateTime(2026, 3);
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
        content: Text('${pagamento.contaNome} paga!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(''), // ✅ ÚNICO TÍTULO!
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),

                // Seletor de mês (sem título)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _navegarMes(-1),
                        color: AppColors.primary,
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR')
                            .format(_mesSelecionado)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _navegarMes(1),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Cards de resumo
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      _buildResumoCardAPagar(),
                      const SizedBox(width: 16),
                      _buildResumoCardPago(),
                    ],
                  ),
                ),

                // Lista de contas
                Expanded(
                  child: _pagamentos.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _pagamentos.length,
                          itemBuilder: (context, index) =>
                              _buildContaCard(_pagamentos[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
        padding: const EdgeInsets.all(16),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatarValor(_resumo['totalPendente'] ?? 0),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_resumo['qtdPendente'] ?? 0} contas',
              style: const TextStyle(
                fontSize: 12,
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
        padding: const EdgeInsets.all(16),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatarValor(_resumo['totalPago'] ?? 0),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_resumo['qtdPago'] ?? 0} contas',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContaCard(PagamentoMes pagamento) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _dbHelper.database.then((db) => db.query('contas',
              where: 'id = ?',
              whereArgs: [
                pagamento.contaId
              ]).then((r) => r.isNotEmpty ? r.first : null)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()));
        }

        final contaData = snapshot.data;
        final isParcelada = contaData?['tipo'] == 'parcelada';

        String? infoParcela;
        if (isParcelada && contaData != null) {
          try {
            final dataInicio =
                DateTime.parse(contaData['data_inicio'] as String);
            final mesInicio = dataInicio.year * 100 + dataInicio.month;
            final mesAtual = pagamento.anoMes;

            if (mesAtual >= mesInicio) {
              final parcelaAtual = (mesAtual - mesInicio) + 1;
              final totalParcelas = contaData['parcelas_total'] as int? ?? 0;
              if (parcelaAtual <= totalParcelas) {
                infoParcela = '$parcelaAtual/$totalParcelas';
              }
            }
          } catch (e) {
            // ignora erro
          }
        }

        final atrasado = pagamento.estaAtrasado && !pagamento.estaPago;
        final cor = pagamento.estaPago
            ? AppColors.success
            : (atrasado ? AppColors.error : AppColors.primary);

        final corFundo = pagamento.estaPago
            ? AppColors.successLight
            : (atrasado ? AppColors.errorLight : AppColors.primaryLight);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Ícone do card
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: corFundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pagamento.estaPago
                      ? Icons.check_circle
                      : (atrasado ? Icons.warning_amber : Icons.receipt),
                  color: cor,
                ),
              ),
              const SizedBox(width: 16),

              // Nome da conta e vencimento
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pagamento.contaNome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vence ${pagamento.dataVencimentoFormatada}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de parcela (se for parcelada)
              if (infoParcela != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    infoParcela,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Valor e botão PAGAR
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatarValor(pagamento.valor),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                  if (!pagamento.estaPago) const SizedBox(height: 8),
                  if (!pagamento.estaPago)
                    SizedBox(
                      width: 70,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _pagarConta(pagamento),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'PAGAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
          Icon(Icons.receipt_outlined, size: 64, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conta para este mês',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
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
            icon: const Icon(Icons.add),
            label: const Text(
              'ADICIONAR CONTA',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
