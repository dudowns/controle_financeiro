// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../repositories/lancamento_repository.dart';
import '../repositories/investimento_repository.dart';
import '../models/investimento_model.dart';
import '../services/backup_service_plus.dart';
import '../utils/date_helper.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/gradient_card.dart';
import '../widgets/primary_card.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/animated_counter.dart';
import '../widgets/grafico_evolucao.dart'; // 🔥 IMPORT DO GRÁFICO
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/formatters.dart';
import '../services/performance_service.dart';

class DashboardData {
  final double saldo;
  final double receitas;
  final double despesas;
  final Map<String, double> gastosPorCategoria;
  final DateTime mesReferencia;
  final int totalLancamentos;

  const DashboardData({
    required this.saldo,
    required this.receitas,
    required this.despesas,
    required this.gastosPorCategoria,
    required this.mesReferencia,
    required this.totalLancamentos,
  });

  bool get temDados => receitas > 0 || despesas > 0;
  bool get temGastos => gastosPorCategoria.isNotEmpty;
  double get totalMovimentado => receitas + despesas;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final LancamentoRepository _lancamentoRepo = LancamentoRepository();
  final InvestimentoRepository _investimentoRepo = InvestimentoRepository();
  final BackupServicePlus _backupService = BackupServicePlus();

  // Dados do dashboard financeiro
  DashboardData? _dados;

  // Dados de investimentos para o gráfico
  List<Map<String, dynamic>> _dadosEvolucao = [];
  double _totalInvestido = 0;
  double _patrimonioTotal = 0;
  bool _carregandoInvestimentos = true;

  bool _carregando = true;
  bool _primeiraCarga = true;
  String? _erro;

  late DateTime _mesSelecionado;
  final Map<DateTime, DashboardData> _cache = {};

  late AnimationController _animationController;

  Map<String, dynamic> _infoBackup = {'existe': false};
  bool _carregandoBackup = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
    _carregarDados();
    _carregarDadosInvestimentos();
    _carregarInfoBackup();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ========== CARREGAR DADOS DE INVESTIMENTOS ==========
  Future<void> _carregarDadosInvestimentos() async {
    setState(() => _carregandoInvestimentos = true);

    try {
      final investimentos = await _investimentoRepo.getAllInvestimentosModel();
      final rendaFixa = await DBHelper().getAllRendaFixa();

      // Calcular totais
      _totalInvestido = 0;
      _patrimonioTotal = 0;

      for (var inv in investimentos) {
        _totalInvestido += inv.valorInvestido;
        _patrimonioTotal += inv.valorAtual;
      }

      for (var rf in rendaFixa) {
        _totalInvestido += rf['valor'] ?? 0;
        _patrimonioTotal += rf['valor_final'] ?? rf['valor'] ?? 0;
      }

      // Gerar dados de evolução mensal
      _dadosEvolucao = await _gerarEvolucaoMensal(investimentos, rendaFixa);
    } catch (e) {
      debugPrint('❌ Erro ao carregar investimentos: $e');
    } finally {
      if (mounted) {
        setState(() => _carregandoInvestimentos = false);
      }
    }
  }

  // ========== GERAR EVOLUÇÃO MENSAL - CORRIGIDO PARA 2026 ==========
  Future<List<Map<String, dynamic>>> _gerarEvolucaoMensal(
    List<Investimento> investimentos,
    List<Map<String, dynamic>> rendaFixa,
  ) async {
    final Map<int, Map<String, double>> evolucao = {};

    // 🔥 FORÇAR ANO 2026
    const int anoForcado = 2026;

    // Processar investimentos
    for (var inv in investimentos) {
      final mes = inv.dataCompra.month;

      if (!evolucao.containsKey(mes)) {
        evolucao[mes] = {'investido': 0, 'patrimonio': 0};
      }

      evolucao[mes]!['investido'] =
          (evolucao[mes]!['investido'] ?? 0) + inv.valorInvestido;
      evolucao[mes]!['patrimonio'] =
          (evolucao[mes]!['patrimonio'] ?? 0) + inv.valorAtual;
    }

    // Processar renda fixa
    for (var rf in rendaFixa) {
      final dataAplicacao = DateTime.parse(rf['data_aplicacao']);
      final mes = dataAplicacao.month;

      if (!evolucao.containsKey(mes)) {
        evolucao[mes] = {'investido': 0, 'patrimonio': 0};
      }

      evolucao[mes]!['investido'] =
          (evolucao[mes]!['investido'] ?? 0) + (rf['valor'] ?? 0);
      evolucao[mes]!['patrimonio'] = (evolucao[mes]!['patrimonio'] ?? 0) +
          (rf['valor_final'] ?? rf['valor'] ?? 0);
    }

    // Acumular valores mês a mês
    double investidoAcumulado = 0;
    double patrimonioAcumulado = 0;
    final List<Map<String, dynamic>> resultado = [];

    for (int mes = 1; mes <= 12; mes++) {
      if (evolucao.containsKey(mes)) {
        investidoAcumulado += evolucao[mes]!['investido']!;
        patrimonioAcumulado += evolucao[mes]!['patrimonio']!;
      }

      resultado.add({
        'data': DateTime(anoForcado, mes, 1),
        'investido': investidoAcumulado,
        'patrimonio': patrimonioAcumulado,
      });
    }

    return resultado;
  }

  Future<void> _carregarInfoBackup() async {
    if (!mounted) return;
    setState(() => _carregandoBackup = true);
    try {
      final backups = await _backupService.listarBackups();
      if (backups.isNotEmpty) {
        final ultimoBackup = backups.first;
        final nome = ultimoBackup.path.split('\\').last;

        DateTime? dataBackup = DateHelper.dataDoNomeArquivo(nome);

        if (dataBackup == null) {
          final dataUtc = await ultimoBackup.lastModified();
          dataBackup = DateHelper.utcParaBrasilia(dataUtc);
        }

        if (mounted) {
          setState(() {
            _infoBackup = {
              'existe': true,
              'data': dataBackup,
              'caminho': ultimoBackup.path,
            };
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _infoBackup = {'existe': false};
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar backup: $e');
      if (mounted) {
        setState(() {
          _infoBackup = {'existe': false};
        });
      }
    } finally {
      if (mounted) {
        setState(() => _carregandoBackup = false);
      }
    }
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;

    PerformanceService.start('carregarDashboard');

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      if (_cache.containsKey(_mesSelecionado)) {
        if (mounted) {
          setState(() {
            _dados = _cache[_mesSelecionado];
            _carregando = false;
            _primeiraCarga = false;
          });
        }
        PerformanceService.stop('carregarDashboard');
        return;
      }

      final lancamentos = await _lancamentoRepo.getAllLancamentos();
      final dados = _processarLancamentos(lancamentos, _mesSelecionado);

      _cache[_mesSelecionado] = dados;

      if (_cache.length > 6) {
        final chavesAntigas = _cache.keys.take(_cache.length - 6).toList();
        for (var chave in chavesAntigas) {
          _cache.remove(chave);
        }
      }

      if (mounted) {
        setState(() {
          _dados = dados;
          _carregando = false;
          _primeiraCarga = false;
        });
      }

      PerformanceService.stop('carregarDashboard');
    } catch (e) {
      debugPrint('❌ Erro ao carregar dashboard: $e');
      if (mounted) {
        setState(() {
          _erro = 'Erro ao carregar dados. Tente novamente.';
          _carregando = false;
          _primeiraCarga = false;
        });
      }
    }
  }

  DashboardData _processarLancamentos(
    List<Map<String, dynamic>> lancamentos,
    DateTime mes,
  ) {
    double totalReceitas = 0;
    double totalDespesas = 0;
    final gastosPorCategoria = <String, double>{};
    int totalLancamentos = 0;

    final primeiroDiaDoMes = DateTime(mes.year, mes.month, 1);
    final ultimoDiaDoMes = DateTime(mes.year, mes.month + 1, 0);

    for (var item in lancamentos) {
      try {
        final dataLancamento = DateTime.parse(item['data'] as String);

        if (dataLancamento.isBefore(primeiroDiaDoMes) ||
            dataLancamento.isAfter(ultimoDiaDoMes)) {
          continue;
        }

        final valor = _extrairValorSeguro(item["valor"]);
        if (valor <= 0) continue;

        totalLancamentos++;

        if (item["tipo"]?.toString().toLowerCase() == "receita") {
          totalReceitas += valor;
        } else {
          totalDespesas += valor;

          final categoria = item["categoria"]?.toString() ?? "Outros";
          gastosPorCategoria[categoria] =
              (gastosPorCategoria[categoria] ?? 0) + valor;
        }
      } catch (e, stackTrace) {
        debugPrint('Erro ao processar lançamento: $e\n$stackTrace');
        continue;
      }
    }

    final categoriasOrdenadas = Map.fromEntries(
        gastosPorCategoria.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));

    return DashboardData(
      saldo: totalReceitas - totalDespesas,
      receitas: totalReceitas,
      despesas: totalDespesas,
      gastosPorCategoria: categoriasOrdenadas,
      mesReferencia: mes,
      totalLancamentos: totalLancamentos,
    );
  }

  double _extrairValorSeguro(dynamic valorBruto) {
    if (valorBruto == null) return 0;
    if (valorBruto is double) return valorBruto;
    if (valorBruto is int) return valorBruto.toDouble();
    if (valorBruto is String) {
      final valorStr = valorBruto.trim().replaceAll(',', '.');
      return double.tryParse(valorStr) ?? 0;
    }
    return 0;
  }

  void _navegarMes(int delta) {
    setState(() {
      _mesSelecionado = DateTime(
        _mesSelecionado.year,
        _mesSelecionado.month + delta,
      );
    });
    _carregarDados();
  }

  Widget _buildLembreteBackup() {
    if (_carregandoBackup) return const SizedBox.shrink();

    if (!_infoBackup['existe']) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Nenhum backup encontrado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                final caminho = await _backupService.salvarBackupEmArquivo();
                if (caminho != null && mounted) {
                  await _carregarInfoBackup();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Backup realizado!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Fazer agora'),
            ),
          ],
        ),
      );
    }

    final dataBackup = _infoBackup['data'] as DateTime;
    final hoje = DateHelper.agoraBrasilia();

    final dataBackupSemHora =
        DateTime(dataBackup.year, dataBackup.month, dataBackup.day);
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final diasAtras = hojeSemHora.difference(dataBackupSemHora).inDays;

    final cor = diasAtras > 7 ? Colors.orange : AppColors.success;
    final corFundo = diasAtras > 7
        ? Colors.orange.shade50
        : AppColors.success.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            diasAtras > 7 ? Icons.warning_amber : Icons.backup,
            color: cor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Último backup',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(dataBackup),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            diasAtras == 0
                ? 'Hoje'
                : diasAtras == 1
                    ? 'Ontem'
                    : 'Há $diasAtras dias',
            style: TextStyle(
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_primeiraCarga) {
      return const _DashboardSkeleton();
    }

    if (_carregando) {
      return const LoadingIndicator(message: 'Carregando dashboard...');
    }

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSizes.iconXL,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: AppSizes.paddingL),
            Text(
              _erro!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingL),
            GradientButton(
              text: 'Tentar novamente',
              icon: Icons.refresh,
              onPressed: () {
                _cache.clear();
                _carregarDados();
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _carregarDados();
        await _carregarDadosInvestimentos();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabecalho(),
            const SizedBox(height: AppSizes.paddingXL),
            _buildLembreteBackup(),
            if (_dados == null || !_dados!.temDados)
              _buildSemDados()
            else ...[
              _buildSaldoCard(),
              const SizedBox(height: AppSizes.paddingXL),
              _buildResumoRapido(),
              const SizedBox(height: AppSizes.paddingXL),
              _buildGraficos(),

              // 🔥 GRÁFICO DE INVESTIMENTOS
              if (!_carregandoInvestimentos && _dadosEvolucao.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingXL),
                GraficoEvolucao(
                  dados: _dadosEvolucao,
                  valorInvestido: _totalInvestido,
                  patrimonioAtual: _patrimonioTotal,
                ),
              ],

              const SizedBox(height: AppSizes.paddingL),
              _buildEstatisticas(),
            ],
            const SizedBox(height: AppSizes.paddingL),
            _buildAtualizarBotao(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return FadeTransition(
      opacity: _animationController,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navegarMes(-1),
                  color: AppColors.primary,
                ),
                Text(
                  Formatador.mesAno(_mesSelecionado),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navegarMes(1),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemDados() {
    return EmptyState(
      icon: Icons.pie_chart_outline,
      message: 'Nenhum lançamento em ${Formatador.mesAno(_mesSelecionado)}',
      buttonText: 'Adicionar lançamento',
      onButtonPressed: () {
        Navigator.pushNamed(context, '/nova-transacao');
      },
    );
  }

  Widget _buildSaldoCard() {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Saldo Total",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
                child: Text(
                  '${_dados?.totalLancamentos ?? 0} lançamentos',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingS),
          AnimatedCounter(
            value: _dados?.saldo ?? 0,
            formatter: Formatador.moeda,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.paddingXS),
          Text(
            'Mês de ${Formatador.mesAno(_mesSelecionado)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoRapido() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Receitas',
            _dados?.receitas ?? 0,
            Icons.arrow_upward,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.paddingM),
        Expanded(
          child: _buildInfoCard(
            'Despesas',
            _dados?.despesas ?? 0,
            Icons.arrow_downward,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String titulo, double valor, IconData icone, Color cor) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: AppSizes.iconXS, color: cor),
              const SizedBox(width: AppSizes.paddingXS),
              Text(
                titulo,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingS),
          AnimatedCounter(
            value: valor,
            formatter: Formatador.moeda,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficos() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildGraficoReceitasDespesas()),
          const SizedBox(width: AppSizes.paddingM),
          Expanded(child: _buildGraficoCategorias()),
        ],
      ),
    );
  }

  Widget _buildGraficoReceitasDespesas() {
    final temDados = (_dados?.receitas ?? 0) + (_dados?.despesas ?? 0) > 0;

    return ModernCard(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!temDados)
            const Center(
              child: Text(
                'Sem dados',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 70,
                sections: [
                  PieChartSectionData(
                    value: _dados!.receitas,
                    color: AppColors.success,
                    radius: 80,
                    title:
                        '${((_dados!.receitas / _dados!.totalMovimentado) * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.5,
                  ),
                  PieChartSectionData(
                    value: _dados!.despesas,
                    color: AppColors.error,
                    radius: 80,
                    title:
                        '${((_dados!.despesas / _dados!.totalMovimentado) * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.5,
                  ),
                ],
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              AnimatedCounter(
                value: _dados?.totalMovimentado ?? 0,
                formatter: Formatador.moeda,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Text(
                  'R: ${((_dados?.receitas ?? 0) / (_dados?.totalMovimentado ?? 1) * 100).toStringAsFixed(0)}% | D: ${((_dados?.despesas ?? 0) / (_dados?.totalMovimentado ?? 1) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoCategorias() {
    if (_dados == null || !_dados!.temGastos) {
      return const ModernCard(
        height: 250,
        child: Center(
          child: Text(
            'Nenhum gasto\nno período',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final todasCategorias = _dados!.gastosPorCategoria.entries.toList();

    final Map<String, double> dadosGrafico = {};
    double outrosValor = 0;

    for (var entry in todasCategorias) {
      final percentual = (entry.value / _dados!.despesas) * 100;

      if (percentual >= 5) {
        dadosGrafico[entry.key] = entry.value;
      } else {
        outrosValor += entry.value;
      }
    }

    if (outrosValor > 0) {
      dadosGrafico['Outros'] = outrosValor;
    }

    return ModernCard(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 70,
              sections: dadosGrafico.entries.map((entry) {
                final percentual = (entry.value / _dados!.despesas) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  color: AppColors.categoryColors[entry.key] ?? Colors.grey,
                  radius: 80,
                  title: '${entry.key}\n${percentual.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.5,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Gastos",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              AnimatedCounter(
                value: _dados!.despesas,
                formatter: Formatador.moeda,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticas() {
    if (_dados == null) return const SizedBox.shrink();

    final diasNoMes =
        DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0).day;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Estatísticas do período',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.paddingL),
          _buildEstatisticaItem(
            'Média de gastos por dia',
            _dados!.despesas / diasNoMes,
          ),
          const Divider(height: AppSizes.paddingXL),
          _buildEstatisticaItem(
            'Maior gasto (categoria)',
            _dados!.gastosPorCategoria.isNotEmpty
                ? _dados!.gastosPorCategoria.entries.first.value
                : 0,
            label: _dados!.gastosPorCategoria.isNotEmpty
                ? _dados!.gastosPorCategoria.entries.first.key
                : null,
          ),
          const Divider(height: AppSizes.paddingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Taxa de economia',
                style: TextStyle(fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: _dados!.saldo >= 0
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
                child: Text(
                  '${((_dados!.saldo / (_dados!.receitas > 0 ? _dados!.receitas : 1)) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _dados!.saldo >= 0
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticaItem(String titulo, double valor, {String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (label != null)
            Container(
              margin: const EdgeInsets.only(right: AppSizes.paddingS),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          AnimatedCounter(
            value: valor,
            formatter: Formatador.moeda,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtualizarBotao() {
    return Center(
      child: GradientButton(
        text: 'Atualizar dados',
        icon: Icons.refresh,
        onPressed: () {
          _cache.clear();
          _carregarDados();
          _carregarDadosInvestimentos();
        },
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                child: Container(
                  width: 150,
                  height: 30,
                  color: Colors.white,
                ),
              ),
              SkeletonLoader(
                child: Container(
                  width: 120,
                  height: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingXL),
          SkeletonLoader(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingXL),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingXL),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingXL),
          SkeletonLoader(
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
