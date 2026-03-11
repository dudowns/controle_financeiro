// lib/screens/investimentos_tabs.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../repositories/investimento_repository.dart'; // NOVO
import '../repositories/provento_repository.dart'; // NOVO
import '../models/investimento_model.dart'; // NOVO
import '../models/provento_model.dart'; // NOVO
import '../services/yahoo_finance_service.dart';
import '../services/notification_service.dart';
import '../services/performance_service.dart';
import 'detalhes_ativo.dart';
import 'grafico_ativo.dart';
import 'proventos.dart';
import 'editar_investimento.dart';
import 'adicionar_investimento.dart';
import 'novo_investimento_dialog.dart';
import '../models/renda_fixa_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_animations.dart';
import '../widgets/primary_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

// =============================================================================
// INVESTIMENTOS TABS SCREEN
// =============================================================================

class InvestimentosTabsScreen extends StatefulWidget {
  const InvestimentosTabsScreen({super.key});

  @override
  State<InvestimentosTabsScreen> createState() =>
      _InvestimentosTabsScreenState();
}

class _InvestimentosTabsScreenState extends State<InvestimentosTabsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // ===========================================================================
  // REPOSITÓRIOS
  // ===========================================================================
  final InvestimentoRepository _investimentoRepo = InvestimentoRepository();
  final ProventoRepository _proventoRepo = ProventoRepository();
  final YahooFinanceService _yahooService = YahooFinanceService();

  // ===========================================================================
  // CONTROLADORES
  // ===========================================================================
  late TabController _tabController;
  late AnimationController _animationController;

  // ===========================================================================
  // DADOS
  // ===========================================================================
  List<Investimento> investimentos = [];
  List<Provento> proventos = [];
  List<Map<String, dynamic>> rendaFixa = [];

  // ===========================================================================
  // ESTADOS
  // ===========================================================================
  bool carregando = true;
  bool _primeiraCarga = true;
  bool atualizando = false;

  // ===========================================================================
  // ESTATÍSTICAS
  // ===========================================================================
  double patrimonioTotal = 0;
  double valorInvestido = 0;
  double ganhoCapital = 0;
  double dividendosRecebidos = 0;
  double proventos12Meses = 0;
  final Map<String, double> valorPorTipo = {};

  // ===========================================================================
  // CORES
  // ===========================================================================
  static final Color _profitText = const Color(0xFF4CAF50);
  static final Color _lossText = const Color(0xFFB71C1C);
  static final Color _profitBg = const Color(0xFFC8E6C9);
  static final Color _lossBg = const Color(0xFFFFEBEE);

  final Map<String, Color> coresPorTipo = {
    'ACAO': Colors.blue,
    'FII': Colors.green,
    'ETF': Colors.purple,
    'BDR': Colors.orange,
    'CRIPTO': Colors.amber,
    'RENDA_FIXA': Colors.teal,
  };

  @override
  bool get wantKeepAlive => true;

  // ===========================================================================
  // INIT STATE
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CARREGAR DADOS
  // ===========================================================================
  Future<void> carregarDados() async {
    PerformanceService.start('carregarInvestimentos');

    setState(() => carregando = true);

    try {
      // Carregar investimentos como modelos
      final investimentosData =
          await _investimentoRepo.getAllInvestimentosModel();
      investimentos = investimentosData;

      // Carregar proventos
      final proventosData = await _proventoRepo.getAll();
      proventos = proventosData;

      // Carregar renda fixa (ainda como Map, precisa de modelo)
      rendaFixa = await DBHelper().getAllRendaFixa();

      _calcularEstatisticas();
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados: $e');
    }

    PerformanceService.stop('carregarInvestimentos');

    setState(() {
      carregando = false;
      _primeiraCarga = false;
    });
  }

  // ===========================================================================
  // CALCULAR ESTATÍSTICAS
  // ===========================================================================
  void _calcularEstatisticas() {
    patrimonioTotal = 0;
    valorInvestido = 0;
    dividendosRecebidos = 0;
    proventos12Meses = 0;
    valorPorTipo.clear();

    final agora = DateTime.now();
    final umAnoAtras = DateTime(agora.year - 1, agora.month, agora.day);

    // Consolidar investimentos para estatísticas
    final investimentosConsolidados =
        _investimentoRepo.consolidarInvestimentos(investimentos);

    for (var item in investimentosConsolidados) {
      patrimonioTotal += item.valorAtual;
      valorInvestido += item.valorInvestido;

      final tipo = item.tipo.nome;
      valorPorTipo[tipo] = (valorPorTipo[tipo] ?? 0) + item.valorAtual;
    }

    // Calcular renda fixa
    for (var item in rendaFixa) {
      final valorFinal = item['valor_final'] ?? item['valor'] ?? 0;
      patrimonioTotal += valorFinal;
      valorInvestido += (item['valor'] ?? 0);
      valorPorTipo['RENDA_FIXA'] =
          (valorPorTipo['RENDA_FIXA'] ?? 0) + valorFinal;
    }

    // Calcular dividendos
    for (var p in proventos) {
      dividendosRecebidos += p.totalRecebido;
      if (p.dataPagamento.isAfter(umAnoAtras)) {
        proventos12Meses += p.totalRecebido;
      }
    }

    ganhoCapital = patrimonioTotal - valorInvestido;
  }

  // ===========================================================================
  // CALCULAR EVOLUÇÃO MENSAL
  // ===========================================================================
  Map<String, Map<String, double>> _calcularEvolucaoMensal() {
    final Map<String, Map<String, double>> evolucao = {};

    final investimentosConsolidados =
        _investimentoRepo.consolidarInvestimentos(investimentos);

    for (var item in investimentosConsolidados) {
      final mesAno = DateFormatter.formatMonthShort(item.dataCompra);

      if (!evolucao.containsKey(mesAno)) {
        evolucao[mesAno] = {
          'patrimonio': 0,
          'investido': 0,
        };
      }

      evolucao[mesAno]!['patrimonio'] =
          (evolucao[mesAno]!['patrimonio'] ?? 0) + item.valorAtual;
      evolucao[mesAno]!['investido'] =
          (evolucao[mesAno]!['investido'] ?? 0) + item.valorInvestido;
    }

    return evolucao;
  }

  // ===========================================================================
  // ATUALIZAR PREÇOS
  // ===========================================================================
  Future<void> _atualizarPrecos() async {
    setState(() => atualizando = true);

    int atualizados = 0;
    int comErro = 0;

    for (var item in investimentos) {
      if (item.id == null) continue;

      try {
        final preco = await _yahooService.getPrecoAtual(item.ticker);
        if (preco != null && preco > 0) {
          await _investimentoRepo.updatePrecoAtual(item.id!, preco);
          atualizados++;
        } else {
          comErro++;
        }
      } catch (e) {
        comErro++;
        debugPrint('❌ Erro ao atualizar ${item.ticker}: $e');
      }
    }

    await carregarDados();
    setState(() => atualizando = false);

    NotificationService().addNotification(
      titulo: '📊 Preços Atualizados',
      mensagem:
          '$atualizados ativos atualizados${comErro > 0 ? ', $comErro erros' : ''}',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$atualizados ativos atualizados${comErro > 0 ? ', $comErro erros' : ''}'),
          backgroundColor: comErro > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  // ===========================================================================
  // MÉTODOS DE FORMATAÇÃO
  // ===========================================================================
  String _formatarValor(double valor) => CurrencyFormatter.format(valor);

  String _formatarCompacto(double valor) =>
      CurrencyFormatter.formatCompact(valor);

  String _formatarPercentual(double valor) =>
      CurrencyFormatter.formatPercentual(valor);

  String _formatarQuantidade(double valor) => valor.toStringAsFixed(0);

  // ===========================================================================
  // ABRIR DIALOG RENDA FIXA
  // ===========================================================================
  void _abrirDialogRendaFixa() {
    showDialog(
      context: context,
      builder: (context) => NovoInvestimentoDialog(
        onSalvar: _salvarRendaFixa,
      ),
    );
  }

  Future<void> _salvarRendaFixa(RendaFixaModel investimento) async {
    try {
      await DBHelper().insertRendaFixa(investimento.toJson());
      await carregarDados();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${investimento.nome} adicionado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ===========================================================================
  // MOSTRAR MENU COMPRA/VENDA
  // ===========================================================================
  void _mostrarMenuCompraVenda() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'O que deseja fazer?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.blue),
                ),
                title: const Text(
                  'Comprar Ações/FIIs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    const Text('Adicionar novo investimento em renda variável'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirDialogAdicionar();
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.savings, color: Colors.teal),
                ),
                title: const Text(
                  'Comprar Renda Fixa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('CDB, LCI, Tesouro, etc'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirDialogRendaFixa();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirDialogAdicionar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdicionarInvestimentoScreen(),
      ),
    );
    if (result == true) {
      carregarDados();
    }
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Investimentos'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Carteira'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Análise'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Proventos'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          if (_tabController.index == 0) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.white),
              onSelected: (value) => _ordenarInvestimentos(value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'ticker',
                  child: Text('Ordenar por ticker'),
                ),
                PopupMenuItem(
                  value: 'valor',
                  child: Text('Maior valor'),
                ),
                PopupMenuItem(
                  value: 'rentabilidade',
                  child: Text('Melhor rentabilidade'),
                ),
              ],
            ),
            IconButton(
              icon: atualizando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: atualizando ? null : _atualizarPrecos,
            ),
          ],
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _tabController.index == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 115),
              child: FloatingActionButton(
                backgroundColor: AppColors.primaryPurple,
                onPressed: _mostrarMenuCompraVenda,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [
                      AppColors.primaryPurple,
                      AppColors.secondaryPurple,
                    ]),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _ordenarInvestimentos(String criterio) {
    setState(() {
      final consolidados =
          _investimentoRepo.consolidarInvestimentos(investimentos);
      investimentos = _investimentoRepo.ordenarInvestimentos(
        consolidados,
        criterio: criterio,
      );
    });
  }

  Widget _buildBody() {
    if (_primeiraCarga) {
      return const _InvestimentosSkeleton();
    }

    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildCarteiraTab(),
        _buildAnaliseTab(),
        const ProventosScreen(),
      ],
    );
  }

  // ===========================================================================
  // TAB CARTEIRA
  // ===========================================================================
  Widget _buildCarteiraTab() {
    final investimentosConsolidados =
        _investimentoRepo.consolidarInvestimentos(investimentos);

    if (investimentosConsolidados.isEmpty && rendaFixa.isEmpty) {
      return Center(
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
                Icons.trending_up,
                size: 64,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum investimento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no + para adicionar seu primeiro ativo',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderTurbinado(investimentosConsolidados),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < investimentosConsolidados.length) {
                  return _buildAtivoCardTurbinado(
                      investimentosConsolidados[index]);
                } else {
                  return _buildRendaFixaCard(
                      rendaFixa[index - investimentosConsolidados.length]);
                }
              },
              childCount: investimentosConsolidados.length + rendaFixa.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
      ],
    );
  }

  // ===========================================================================
  // HEADER TURBINADO
  // ===========================================================================
  Widget _buildHeaderTurbinado(List<Investimento> investimentosConsolidados) {
    double totalInvestido = 0;
    double totalAtual = 0;

    for (var item in investimentosConsolidados) {
      totalInvestido += item.valorInvestido;
      totalAtual += item.valorAtual;
    }

    for (var item in rendaFixa) {
      totalInvestido += item['valor'] ?? 0;
      totalAtual += item['valor_final'] ?? item['valor'] ?? 0;
    }

    final rentabilidade = totalInvestido > 0
        ? ((totalAtual - totalInvestido) / totalInvestido) * 100
        : 0;

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PATRIMÔNIO',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${investimentosConsolidados.length + rendaFixa.length} ativos',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedCounter(
                  value: totalAtual,
                  formatter: _formatarValor,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rentabilidade >= 0
                        ? _profitBg.withOpacity(0.2)
                        : _lossBg.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rentabilidade >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 14,
                        color: rentabilidade >= 0 ? _profitText : _lossText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rentabilidade >= 0 ? '+' : ''}${rentabilidade.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: rentabilidade >= 0 ? _profitText : _lossText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Investido',
                    totalInvestido,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Rendimento',
                    totalAtual - totalInvestido,
                    Icons.trending_up,
                    cor: (totalAtual - totalInvestido) >= 0
                        ? _profitText
                        : _lossText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Dividendos',
                    dividendosRecebidos,
                    Icons.monetization_on,
                    cor: _profitText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    double valor,
    IconData icone, {
    Color? cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, size: 16, color: Colors.white70),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: valor,
            formatter: _formatarValor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cor ?? Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD DE ATIVO
  // ===========================================================================
  Widget _buildAtivoCardTurbinado(Investimento item) {
    final cor = coresPorTipo[item.tipo.nome] ?? Colors.grey;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 300 + ((item.id ?? 0) % 300),
      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetalhesAtivoScreen(
                  ativo: item.toJson(),
                ),
              ),
            ).then((_) => carregarDados()),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.tipo.icone,
                      color: cor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.ticker,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.tipo.nome,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatarQuantidade(item.quantidade)} cotas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedCounter(
                            value: item.precoAtual ?? item.precoMedio,
                            formatter: _formatarValor,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.variacaoPercentual >= 0
                                  ? _profitBg
                                  : _lossBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.variacaoPercentual >= 0 ? '+' : ''}${item.variacaoPercentual.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.variacaoPercentual >= 0
                                    ? _profitText
                                    : _lossText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.primaryPurple,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarInvestimentoScreen(
                                investimento: item.toJson(),
                              ),
                            ),
                          );
                          if (result == true) carregarDados();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD DE RENDA FIXA
  // ===========================================================================
  Widget _buildRendaFixaCard(Map<String, dynamic> item) {
    final rendimentoLiquido = (item['rendimento_liquido'] ?? 0).toDouble();
    final valorFinal = (item['valor_final'] ?? item['valor'] ?? 0).toDouble();

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 300 + ((item['id'] as int? ?? 0) % 300),
      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _mostrarDetalhesRendaFixa(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.savings,
                      color: Colors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item['nome'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['tipo_renda'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aplicação: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['data_aplicacao']))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Vencimento: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['data_vencimento']))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedCounter(
                        value: valorFinal,
                        formatter: _formatarValor,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                      if (rendimentoLiquido > 0)
                        Text(
                          '+${_formatarValor(rendimentoLiquido)} (${((rendimentoLiquido / item['valor']) * 100).toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            color: _profitText,
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF6A1B9A),
                            ),
                            onPressed: () => _editarRendaFixa(item),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _excluirRendaFixa(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalhesRendaFixa(Map<String, dynamic> item) {
    // TODO: Implementar detalhes de renda fixa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detalhes de renda fixa em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _editarRendaFixa(Map<String, dynamic> item) {
    // TODO: Implementar edição de renda fixa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edição de renda fixa em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _excluirRendaFixa(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Renda Fixa'),
        content: Text('Deseja realmente excluir ${item['nome']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper().deleteRendaFixa(item['id']);
              await carregarDados();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Renda Fixa excluída!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB ANÁLISE
  // ===========================================================================
  Widget _buildAnaliseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCardPatrimonio(),
          const SizedBox(height: 16),
          _buildCardLucro(),
          const SizedBox(height: 16),
          _buildCardProventosResumo(),
          const SizedBox(height: 16),
          _buildGraficoEvolucao(),
          const SizedBox(height: 16),
          _buildAlocacaoExpansivel(),
          const SizedBox(height: 16),
          _buildCardAlocacao(),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD PATRIMÔNIO
  // ===========================================================================
  Widget _buildCardPatrimonio() {
    final variacaoPercentual =
        valorInvestido > 0 ? (ganhoCapital / valorInvestido) * 100 : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATRIMÔNIO TOTAL',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              _formatarValor(patrimonioTotal),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: variacaoPercentual >= 0
                        ? _profitBg.withOpacity(0.2)
                        : _lossBg.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        variacaoPercentual >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 14,
                        color:
                            variacaoPercentual >= 0 ? _profitText : _lossText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${variacaoPercentual >= 0 ? '+' : ''}${_formatarPercentual(variacaoPercentual)}',
                        style: TextStyle(
                          color:
                              variacaoPercentual >= 0 ? _profitText : _lossText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Investido: ${_formatarValor(valorInvestido)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD LUCRO
  // ===========================================================================
  Widget _buildCardLucro() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LUCRO TOTAL',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Ganho Capital',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedCounter(
                        value: ganhoCapital,
                        formatter: _formatarValor,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ganhoCapital >= 0 ? _profitText : _lossText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Dividendos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedCounter(
                        value: dividendosRecebidos,
                        formatter: _formatarValor,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _profitText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total acumulado:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  AnimatedCounter(
                    value: ganhoCapital + dividendosRecebidos,
                    formatter: _formatarValor,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CARD PROVENTOS RESUMO
  // ===========================================================================
  Widget _buildCardProventosResumo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROVENTOS (12M)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCounter(
                    value: proventos12Meses,
                    formatter: _formatarValor,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _profitText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${_formatarValor(dividendosRecebidos)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                color: AppColors.primaryPurple,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // GRÁFICO EVOLUÇÃO
  // ===========================================================================
  Widget _buildGraficoEvolucao() {
    final evolucao = _calcularEvolucaoMensal();

    if (evolucao.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Sem dados históricos',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adicione investimentos com datas diferentes',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ordenar meses
    var mesesOrdenados = evolucao.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('/');
        final bParts = b.split('/');

        final aAno = int.parse('20${aParts[1]}');
        final bAno = int.parse('20${bParts[1]}');
        final aMes = _getMesNumero(aParts[0]);
        final bMes = _getMesNumero(bParts[0]);

        if (aAno != bAno) return aAno.compareTo(bAno);
        return aMes.compareTo(bMes);
      });

    final valoresPatrimonio =
        mesesOrdenados.map((m) => evolucao[m]!['patrimonio']!).toList();
    final valoresInvestido =
        mesesOrdenados.map((m) => evolucao[m]!['investido']!).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Evolução Mensal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: valoresPatrimonio.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          _formatarValor(rod.toY),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatarCompacto(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < mesesOrdenados.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                mesesOrdenados[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(mesesOrdenados.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: valoresPatrimonio[index],
                          color: AppColors.primaryPurple,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: valoresInvestido[index],
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendaCor('Patrimônio', AppColors.primaryPurple),
                const SizedBox(width: 20),
                _buildLegendaCor('Investido', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getMesNumero(String mesTexto) {
    const meses = {
      'jan': 1,
      'fev': 2,
      'mar': 3,
      'abr': 4,
      'mai': 5,
      'jun': 6,
      'jul': 7,
      'ago': 8,
      'set': 9,
      'out': 10,
      'nov': 11,
      'dez': 12,
    };
    return meses[mesTexto.toLowerCase()] ?? 1;
  }

  // ===========================================================================
  // ALOCAÇÃO EXPANSÍVEL
  // ===========================================================================
  Widget _buildAlocacaoExpansivel() {
    final investimentosConsolidados =
        _investimentoRepo.consolidarInvestimentos(investimentos);
    final investimentosPorTipo =
        _investimentoRepo.agruparPorTipo(investimentosConsolidados);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 ALOCAÇÃO POR ATIVO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (investimentosPorTipo.containsKey('ACAO'))
              _buildExpansionCategoria(
                '📈 AÇÕES',
                Icons.trending_up,
                Colors.blue,
                investimentosPorTipo['ACAO']!,
              ),
            if (investimentosPorTipo.containsKey('FII'))
              _buildExpansionCategoria(
                '🏢 FIIs',
                Icons.apartment,
                Colors.green,
                investimentosPorTipo['FII']!,
              ),
            if (rendaFixa.isNotEmpty)
              _buildExpansionCategoria(
                '💰 RENDA FIXA',
                Icons.savings,
                Colors.teal,
                rendaFixa
                    .map((rf) => Investimento(
                          ticker: rf['nome'],
                          tipo: TipoInvestimentoExtension.fromString(
                              'RENDA_FIXA'),
                          quantidade: 1,
                          precoMedio: rf['valor'],
                          precoAtual: rf['valor_final'] ?? rf['valor'],
                          dataCompra: DateTime.parse(rf['data_aplicacao']),
                        ))
                    .toList(),
              ),
            if (investimentosPorTipo.containsKey('CRIPTO'))
              _buildExpansionCategoria(
                '🪙 CRIPTO',
                Icons.currency_bitcoin,
                Colors.amber,
                investimentosPorTipo['CRIPTO']!,
              ),
            if (investimentosPorTipo.containsKey('ETF'))
              _buildExpansionCategoria(
                '📊 ETFs',
                Icons.show_chart,
                Colors.purple,
                investimentosPorTipo['ETF']!,
              ),
            if (investimentosPorTipo.containsKey('BDR'))
              _buildExpansionCategoria(
                '🌎 BDRs',
                Icons.public,
                Colors.teal,
                investimentosPorTipo['BDR']!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionCategoria(
    String titulo,
    IconData icone,
    Color cor,
    List<Investimento> ativos,
  ) {
    final totalCategoria = ativos.fold<double>(
      0,
      (sum, item) => sum + item.valorAtual,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          title: Text(
            titulo,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          subtitle: Text(
            '${ativos.length} ativos • Total: ${_formatarValor(totalCategoria)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children:
              ativos.map((ativo) => _buildAtivoLinha(ativo, cor)).toList(),
        ),
      ),
    );
  }

  Widget _buildAtivoLinha(Investimento ativo, Color cor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              ativo.ticker,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_formatarQuantidade(ativo.quantidade)} ${ativo.quantidade == 1 ? 'operação' : 'operações'}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatarValor(ativo.valorAtual),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ativo.variacaoPercentual >= 0 ? _profitBg : _lossBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ativo.variacaoPercentual >= 0 ? '+' : ''}${ativo.variacaoPercentual.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: ativo.variacaoPercentual >= 0 ? _profitText : _lossText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD ALOCAÇÃO
  // ===========================================================================
  Widget _buildCardAlocacao() {
    final total = valorPorTipo.values.fold(0.0, (a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo por Tipo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...valorPorTipo.entries.map((entry) {
              final percentual = total > 0 ? (entry.value / total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getNomeTipo(entry.key),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _formatarPercentual(percentual),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentual / 100,
                      backgroundColor: Colors.grey[200],
                      color: _getCorTipo(entry.key),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getNomeTipo(String tipo) {
    switch (tipo) {
      case 'ACAO':
        return '📈 Ações';
      case 'FII':
        return '🏢 FIIs';
      case 'RENDA_FIXA':
        return '💰 Renda Fixa';
      case 'CRIPTO':
        return '🪙 Cripto';
      default:
        return tipo;
    }
  }

  Color _getCorTipo(String tipo) {
    switch (tipo) {
      case 'ACAO':
        return Colors.blue;
      case 'FII':
        return Colors.green;
      case 'RENDA_FIXA':
        return Colors.teal;
      case 'CRIPTO':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegendaCor(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// =============================================================================
// SKELETON LOADING
// =============================================================================
class _InvestimentosSkeleton extends StatelessWidget {
  const _InvestimentosSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: SkeletonLoader(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
