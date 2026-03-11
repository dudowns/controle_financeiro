// lib/screens/proventos.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../repositories/provento_repository.dart';
import '../models/provento_model.dart';
import '../utils/date_helper.dart';
import 'editar_provento.dart';
import 'adicionar_provento.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_animations.dart';
import '../widgets/primary_card.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/animated_counter.dart';
import '../widgets/glassmorphism.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../services/performance_service.dart';

class ProventosScreen extends StatefulWidget {
  const ProventosScreen({super.key});

  @override
  State<ProventosScreen> createState() => _ProventosScreenState();
}

class _ProventosScreenState extends State<ProventosScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ProventoRepository _proventoRepo = ProventoRepository();

  List<Provento> proventos = [];
  Map<String, dynamic>? estatisticas;

  bool carregando = true;
  bool _primeiraCarga = true;

  late AnimationController _animationController;
  late AnimationController _chartAnimationController;

  static const Color _profitText = Color(0xFF4CAF50);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _carregarDados();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    PerformanceService.start('carregarProventos');

    setState(() => carregando = true);

    try {
      proventos = await _proventoRepo.getAll();
      estatisticas = await _proventoRepo.getEstatisticas();
    } catch (e) {
      debugPrint('❌ Erro ao carregar proventos: $e');
    }

    PerformanceService.stop('carregarProventos');

    setState(() {
      carregando = false;
      _primeiraCarga = false;
    });
  }

  List<Provento> _getProximosProventos() {
    final hoje = DateHelper.agoraBrasilia();
    final proximos =
        proventos.where((p) => p.dataPagamento.isAfter(hoje)).toList();
    proximos.sort((a, b) => a.dataPagamento.compareTo(b.dataPagamento));
    return proximos.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Proventos'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdicionarProventoScreen(),
            ),
          );
          if (result == true) {
            _carregarDados();
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_primeiraCarga) {
      return const _ProventosSkeleton();
    }

    if (carregando) {
      return const LoadingIndicator(message: 'Carregando proventos...');
    }

    return proventos.isEmpty ? _buildEmptyState() : _buildContent();
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.monetization_on,
      message: 'Nenhum provento registrado',
      buttonText: 'Adicionar provento',
      onButtonPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdicionarProventoScreen(),
          ),
        );
        if (result == true) {
          _carregarDados();
        }
      },
    );
  }

  Widget _buildContent() {
    final proximos = _getProximosProventos();

    return FadeTransition(
      opacity: _animationController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResumoCards(),
            const SizedBox(height: AppSizes.paddingL),
            _buildGraficoEvolucao(),
            const SizedBox(height: AppSizes.paddingL),
            if (proximos.isNotEmpty) ...[
              _buildProximosProventos(proximos),
              const SizedBox(height: AppSizes.paddingL),
            ],
            const Text(
              'Histórico de Proventos',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: AppSizes.paddingM),
            ...proventos.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              return _buildProventoCard(p, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCards() {
    final total = estatisticas?['total'] ?? 0.0;
    final mes = estatisticas?['mes'] ?? 0.0;
    final ultimos12Meses = estatisticas?['ultimos12Meses'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildResumoCard(
            'Total',
            total,
            Icons.account_balance_wallet,
            AppColors.primaryPurple,
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),
        Expanded(
          child: _buildResumoCard(
            'Este mês',
            mes,
            Icons.calendar_today,
            _profitText,
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),
        Expanded(
          child: _buildResumoCard(
            '12 meses',
            ultimos12Meses,
            Icons.calendar_view_month,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildResumoCard(
      String titulo, double valor, IconData icone, Color cor) {
    return Glassmorphism(
      blur: 10,
      opacity: 0.1,
      borderRadius: AppSizes.radiusL,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: AppSizes.iconS),
                const SizedBox(width: AppSizes.paddingXS),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: cor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingS),
            AnimatedCounter(
              value: valor,
              formatter: CurrencyFormatter.format,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoEvolucao() {
    final porMes = estatisticas?['porMes'] as Map<String, double>? ?? {};

    if (porMes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: const Center(
          child: Text('Sem dados para exibir'),
        ),
      );
    }

    // Pegar últimos 6 meses
    final agora = DateHelper.agoraBrasilia();
    final List<Map<String, dynamic>> dadosGrafico = [];

    for (int i = 5; i >= 0; i--) {
      final data = DateTime(agora.year, agora.month - i, 1);
      final chave = DateFormat('MM/yyyy').format(data);
      final valor = porMes[chave] ?? 0.0;
      final mes = DateFormat('MMM').format(data);

      dadosGrafico.add({
        'mes': mes,
        'valor': valor,
        'data': data,
      });
    }

    final maxValor = dadosGrafico
        .map((e) => e['valor'] as double)
        .reduce((a, b) => a > b ? a : b);
    const double alturaMaxima = 120.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Evolução Mensal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.paddingL),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dadosGrafico.map((item) {
                final valor = item['valor'] as double;
                final mes = item['mes'] as String;

                double barraAltura =
                    maxValor > 0 ? (valor / maxValor) * alturaMaxima : 4.0;

                if (barraAltura < 4.0 && valor > 0) barraAltura = 4.0;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatCompact(valor),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: valor > 0 ? _profitText : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: barraAltura,
                        width: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: valor > 0
                                ? [
                                    AppColors.primaryPurple,
                                    AppColors.secondaryPurple
                                  ]
                                : [Colors.grey[300]!, Colors.grey[200]!],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mes,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximosProventos(List<Provento> proximos) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.event_available,
                    color: Colors.orange, size: AppSizes.iconM),
              ),
              const SizedBox(width: AppSizes.paddingM),
              const Text(
                '📅 Próximos Proventos',
                style: AppTextStyles.subtitle2,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          ...proximos.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            return _buildProximoItem(p, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProximoItem(Provento p, int index) {
    final hoje = DateHelper.agoraBrasilia();
    final diasRestantes = p.dataPagamento.difference(hoje).inDays;
    final isRendaFixa = p.tipo == TipoProvento.rendaFixa;
    final cor = isRendaFixa ? Colors.teal : _profitText;
    final icone = isRendaFixa ? Icons.savings : Icons.trending_up;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(icone, color: cor, size: AppSizes.iconS),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.ticker,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormatter.formatDate(p.dataPagamento)} • $diasRestantes dias',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedCounter(
                  value: p.totalRecebido,
                  formatter: CurrencyFormatter.format,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'em $diasRestantes dias',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProventoCard(Provento item, int index) {
    final isRendaFixa = item.tipo == TipoProvento.rendaFixa;
    final cor = isRendaFixa
        ? Colors.teal
        : (item.ticker.contains('11') ? Colors.green : _profitText);
    final icone = isRendaFixa
        ? Icons.savings
        : (item.ticker.contains('11') ? Icons.apartment : Icons.trending_up);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 50)),
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
      child: ModernCard(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditarProventoScreen(provento: item.toJson()),
            ),
          );
          if (result == true) {
            _carregarDados();
          }
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(icone, color: cor, size: AppSizes.iconM),
            ),
            const SizedBox(width: AppSizes.paddingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ticker,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    '${item.tipo.nome} • ${DateFormatter.formatDate(item.dataPagamento)}',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    '${item.quantidade.toStringAsFixed(0)} cotas • ${CurrencyFormatter.format(item.valorPorCota)}/cota',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCounter(
              value: item.totalRecebido,
              formatter: CurrencyFormatter.format,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProventosSkeleton extends StatelessWidget {
  const _ProventosSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: SkeletonLoader(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          SkeletonLoader(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingL),
          ...List.generate(
              3,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                    child: SkeletonLoader(
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        ),
                      ),
                    ),
                  )),
        ],
      ),
    );
  }
}
