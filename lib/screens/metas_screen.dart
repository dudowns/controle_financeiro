// lib/screens/metas_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../repositories/meta_repository.dart'; // NOVO: import do repositório
import 'nova_meta_screen.dart';
import 'detalhes_meta_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_animations.dart';
import '../widgets/primary_card.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/animated_counter.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../services/performance_service.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // 🔥 MUDANÇA 1: Usar o repositório ao invés do DBHelper diretamente
  final MetaRepository _metaRepo = MetaRepository();

  List<Map<String, dynamic>> metas = [];
  Map<String, dynamic>? estatisticas;

  bool carregando = true;
  bool _primeiraCarga = true;

  // Animações
  late AnimationController _animationController;
  late AnimationController _progressAnimationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _carregarMetas();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  // 🔥 MUDANÇA 2: Método de carregamento usando o repositório
  Future<void> _carregarMetas() async {
    PerformanceService.start('carregarMetas');

    setState(() => carregando = true);

    try {
      // Carregar metas COM os depósitos
      metas = await _metaRepo.getAllMetasComDepositos();

      // Carregar estatísticas
      estatisticas = await _metaRepo.getEstatisticasMetas();
    } catch (e) {
      debugPrint('❌ Erro ao carregar metas: $e');

      // Fallback: carregar só as metas se algo der errado
      metas = await _metaRepo.getAllMetas();
    }

    PerformanceService.stop('carregarMetas');

    setState(() {
      carregando = false;
      _primeiraCarga = false;
    });

    // Iniciar animação de progresso após carregar
    _progressAnimationController.forward();
  }

  // 🔥 MUDANÇA 3: Método para atualizar após adicionar/editar
  Future<void> _atualizarAposAcao() async {
    await _carregarMetas();

    // Reiniciar animação de progresso
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }

  Color _getCorPorTipo(String? cor) {
    switch (cor) {
      case 'viagem':
        return Colors.blue;
      case 'carro':
        return Colors.red;
      case 'casa':
        return Colors.green;
      case 'estudo':
        return Colors.orange;
      case 'investimento':
        return Colors.purple;
      default:
        return AppColors.primaryPurple;
    }
  }

  IconData _getIconePorTipo(String? icone) {
    switch (icone) {
      case 'viagem':
        return Icons.flight;
      case 'carro':
        return Icons.directions_car;
      case 'casa':
        return Icons.home;
      case 'estudo':
        return Icons.school;
      case 'investimento':
        return Icons.trending_up;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Metas'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          // 🔥 NOVO: Botão de estatísticas
          if (estatisticas != null && !carregando)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  ),
                  child: Text(
                    '${estatisticas!['emAndamento']} pendentes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMetas,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NovaMetaScreen(),
            ),
          );
          if (result == true) {
            await _atualizarAposAcao(); // 🔥 Usando o método novo
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_primeiraCarga) {
      return const _MetasSkeleton();
    }

    if (carregando) {
      return const LoadingIndicator(message: 'Carregando metas...');
    }

    return metas.isEmpty ? _buildEmptyState() : _buildList();
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.flag,
      message: 'Nenhuma meta cadastrada',
      buttonText: 'Criar meta',
      onButtonPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NovaMetaScreen(),
          ),
        );
        if (result == true) {
          await _atualizarAposAcao(); // 🔥 Usando o método novo
        }
      },
    );
  }

  Widget _buildList() {
    return FadeTransition(
      opacity: _animationController,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        itemCount: metas.length,
        itemBuilder: (context, index) {
          final meta = metas[index];
          return _buildMetaCard(meta, index);
        },
      ),
    );
  }

  Widget _buildMetaCard(Map<String, dynamic> meta, int index) {
    final valorObjetivo = (meta['valor_objetivo'] ?? 0).toDouble();
    final valorAtual = (meta['valor_atual'] ?? 0).toDouble();
    final progresso = valorObjetivo > 0 ? valorAtual / valorObjetivo : 0.0;
    final percentual = (progresso * 100).clamp(0, 100);
    final cor = _getCorPorTipo(meta['cor']);
    final icone = _getIconePorTipo(meta['icone']);
    final concluida = meta['concluida'] == 1;

    // 🔥 NOVO: Calcular total de depósitos se existir
    final depositos = meta['depositos'] as List?;
    final totalDepositos = depositos?.length ?? 0;

    // Animação de entrada em cascata
    final delay = index * 100;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
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
              builder: (context) => DetalhesMetaScreen(meta: meta),
            ),
          );
          if (result == true) {
            await _atualizarAposAcao(); // 🔥 Usando o método novo
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: concluida
                ? Border.all(color: AppColors.profitGreen, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ícone animado
                  ScaleTransition(
                    scale: _animationController.drive(
                      CurveTween(curve: Curves.elasticOut),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Icon(icone, color: cor, size: AppSizes.iconM),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta['titulo'] ?? 'Sem título',
                          style: AppTextStyles.subtitle2,
                        ),
                        if (meta['descricao'] != null &&
                            meta['descricao'].toString().isNotEmpty)
                          Text(
                            meta['descricao'],
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // 🔥 NOVO: Mostrar quantidade de depósitos
                        if (totalDepositos > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$totalDepositos ${totalDepositos == 1 ? 'depósito' : 'depósitos'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (concluida)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: AppSizes.paddingXS),
                      decoration: BoxDecoration(
                        color: AppColors.profitGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.profitGreen,
                              size: AppSizes.iconXS),
                          SizedBox(width: AppSizes.paddingXS),
                          Text(
                            'Concluída',
                            style: TextStyle(
                              color: AppColors.profitGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),

              // Valores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atual',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSizes.paddingXS),
                      AnimatedCounter(
                        value: valorAtual,
                        formatter: CurrencyFormatter.format,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Meta',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSizes.paddingXS),
                      AnimatedCounter(
                        value: valorObjetivo,
                        formatter: CurrencyFormatter.format,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                      vertical: AppSizes.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: percentual >= 100
                          ? AppColors.profitGreen.withOpacity(0.1)
                          : cor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: AnimatedCounter(
                      value: percentual,
                      formatter: (value) => '${value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: percentual >= 100 ? AppColors.profitGreen : cor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Barra de progresso animada
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Fundo da barra
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                      // Barra de progresso animada
                      AnimatedBuilder(
                        animation: _progressAnimationController,
                        builder: (context, child) {
                          return Container(
                            height: 10,
                            width: constraints.maxWidth *
                                progresso *
                                _progressAnimationController.value,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: percentual >= 100
                                    ? [AppColors.profitGreen, Colors.green]
                                    : [cor, cor.withOpacity(0.7)],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusS),
                              boxShadow: [
                                BoxShadow(
                                  color: (percentual >= 100
                                          ? AppColors.profitGreen
                                          : cor)
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSizes.paddingM),

              // Informações adicionais
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (meta['data_fim'] != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: AppSizes.iconXS, color: Colors.grey[500]),
                        const SizedBox(width: AppSizes.paddingXS),
                        Text(
                          DateFormatter.formatDate(
                              DateTime.parse(meta['data_fim'])),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: AppSizes.iconXS, color: Colors.grey[500]),
                      const SizedBox(width: AppSizes.paddingXS),
                      AnimatedCounter(
                        value: (valorObjetivo - valorAtual)
                            .clamp(0, valorObjetivo),
                        formatter: CurrencyFormatter.format,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== SKELETON LOADING ==========
class _MetasSkeleton extends StatelessWidget {
  const _MetasSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
          child: SkeletonLoader(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
            ),
          ),
        );
      },
    );
  }
}
