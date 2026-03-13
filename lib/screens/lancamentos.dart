// lib/screens/lancamentos.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../repositories/lancamento_repository.dart';
import '../models/lancamento_model.dart';
import 'nova_transacao.dart';
import 'editar_transacao.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/primary_card.dart';
import '../widgets/modern_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/animated_counter.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/formatters.dart';
import '../services/performance_service.dart';

enum Ordenacao { dataDesc, dataAsc, valorDesc, valorAsc }

class LancamentosScreen extends StatefulWidget {
  const LancamentosScreen({super.key});

  @override
  State<LancamentosScreen> createState() => _LancamentosScreenState();
}

class _LancamentosScreenState extends State<LancamentosScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final LancamentoRepository _lancamentoRepo = LancamentoRepository();

  List<Map<String, dynamic>> lancamentos = [];
  List<Map<String, dynamic>>? _lancamentosFiltradosCache;

  Map<String, dynamic>? _resumoMes;

  bool carregando = true;
  bool _primeiraCarga = true;
  bool _temMaisItens = true;
  int _paginaAtual = 1;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;

  String filtroTipo = 'Todos';
  String filtroCategoria = 'Todas';
  DateTime? dataInicio;
  DateTime? dataFim;
  Ordenacao _ordenacaoAtual = Ordenacao.dataDesc;

  final List<String> tipos = const ['Todos', 'Receita', 'Gasto'];
  final List<String> categorias = const [
    'Todas',
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Investimentos',
    'Outros'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _carregarLancamentos();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _carregarMaisLancamentos();
    }
  }

  Future<void> _carregarLancamentos() async {
    if (!mounted) return;

    PerformanceService.start('carregarLancamentos');

    setState(() {
      carregando = true;
      _paginaAtual = 1;
    });

    try {
      lancamentos = await _lancamentoRepo.getAllLancamentos();
      _lancamentosFiltradosCache = null;
      _temMaisItens = lancamentos.length >= 20;

      await _carregarResumoMes();

      PerformanceService.stop('carregarLancamentos');
    } catch (e) {
      _mostrarErro('Erro ao carregar lançamentos: $e');
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
          _primeiraCarga = false;
        });
      }
    }
  }

  Future<void> _carregarResumoMes() async {
    try {
      _resumoMes = await _lancamentoRepo.getResumoDoMes(DateTime.now());
    } catch (e) {
      debugPrint('❌ Erro ao carregar resumo do mês: $e');
    }
  }

  Future<void> _carregarMaisLancamentos() async {
    if (!_temMaisItens || carregando || !mounted) return;

    try {
      final maisLancamentos = await _lancamentoRepo.getLancamentosPaginados(
        pagina: _paginaAtual + 1,
        tipo: filtroTipo != 'Todos' ? filtroTipo : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      if (mounted) {
        setState(() {
          lancamentos.addAll(maisLancamentos);
          _paginaAtual++;
          _temMaisItens = maisLancamentos.length >= 20;
          _lancamentosFiltradosCache = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarErro('Erro ao carregar mais lançamentos: $e');
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _lancamentosFiltrados {
    if (_lancamentosFiltradosCache != null) {
      return _lancamentosFiltradosCache!;
    }

    final filtrados = lancamentos.where((l) {
      if (filtroTipo != 'Todos') {
        final tipoItem = l['tipo']?.toString().toLowerCase() ?? '';
        final tipoFiltro = filtroTipo.toLowerCase();

        if (tipoFiltro == 'receita' &&
            !(tipoItem == 'receita' || tipoItem == 'receitas')) {
          return false;
        }
        if (tipoFiltro == 'gasto' &&
            !(tipoItem == 'gasto' ||
                tipoItem == 'gastos' ||
                tipoItem == 'despesa')) {
          return false;
        }
      }

      if (filtroCategoria != 'Todas') {
        if (l['categoria'] != filtroCategoria) return false;
      }

      if (dataInicio != null) {
        try {
          final data = DateTime.parse(l['data']);
          if (data.isBefore(dataInicio!)) return false;
        } catch (_) {}
      }

      if (dataFim != null) {
        try {
          final data = DateTime.parse(l['data']);
          if (data.isAfter(dataFim!)) return false;
        } catch (_) {}
      }

      return true;
    }).toList();

    switch (_ordenacaoAtual) {
      case Ordenacao.dataDesc:
        filtrados.sort((a, b) => b['data'].compareTo(a['data']));
        break;
      case Ordenacao.dataAsc:
        filtrados.sort((a, b) => a['data'].compareTo(b['data']));
        break;
      case Ordenacao.valorDesc:
        filtrados.sort((a, b) => (b['valor'] ?? 0).compareTo(a['valor'] ?? 0));
        break;
      case Ordenacao.valorAsc:
        filtrados.sort((a, b) => (a['valor'] ?? 0).compareTo(b['valor'] ?? 0));
        break;
    }

    _lancamentosFiltradosCache = filtrados;
    return filtrados;
  }

  double get _totalReceitas {
    return _lancamentosFiltrados.where((l) {
      final tipo = l['tipo']?.toString().toLowerCase();
      return tipo == 'receita' || tipo == 'receitas';
    }).fold(0, (sum, l) => sum + (l['valor'] ?? 0));
  }

  double get _totalDespesas {
    return _lancamentosFiltrados.where((l) {
      final tipo = l['tipo']?.toString().toLowerCase();
      return tipo == 'gasto' || tipo == 'gastos' || tipo == 'despesa';
    }).fold(0, (sum, l) => sum + (l['valor'] ?? 0));
  }

  double get _saldo => _totalReceitas - _totalDespesas;

  void _limparFiltros() {
    setState(() {
      filtroTipo = 'Todos';
      filtroCategoria = 'Todas';
      dataInicio = null;
      dataFim = null;
      _ordenacaoAtual = Ordenacao.dataDesc;
      _lancamentosFiltradosCache = null;
    });
  }

  void _aplicarFiltros() {
    setState(() {
      _lancamentosFiltradosCache = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _mostrarOpcoesOrdenacao,
            tooltip: 'Ordenar',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtrar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarLancamentos,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NovaTransacaoScreen(),
            ),
          );
          if (result == true) {
            await _carregarLancamentos();
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_primeiraCarga) {
      return const _LancamentosSkeleton();
    }

    if (carregando && lancamentos.isEmpty) {
      return const LoadingIndicator(message: 'Carregando lançamentos...');
    }

    return Column(
      children: [
        _buildResumoCard(),
        if (_filtrosAtivos) _buildFiltrosIndicador(),
        Expanded(
          child: lancamentos.isEmpty
              ? _buildEmptyState()
              : _lancamentosFiltrados.isEmpty
                  ? _buildSemResultados()
                  : _buildLista(),
        ),
      ],
    );
  }

  Widget _buildResumoCard() {
    final receitas = _resumoMes?['receitas'] ?? _totalReceitas;
    final despesas = _resumoMes?['despesas'] ?? _totalDespesas;
    final saldo = _resumoMes?['saldo'] ?? _saldo;

    return Container(
      margin: const EdgeInsets.all(AppSizes.paddingL),
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo do Mês',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  AnimatedCounter(
                    value: saldo,
                    formatter: Formatador.moeda,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingM,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
                child: Text(
                  Formatador.mesAno(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          Row(
            children: [
              Expanded(
                child: _buildResumoItem(
                  'Receitas',
                  receitas,
                  Icons.arrow_upward,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: _buildResumoItem(
                  'Despesas',
                  despesas,
                  Icons.arrow_downward,
                  AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(
      String titulo, double valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          Icon(icone, size: AppSizes.iconXS, color: cor),
          const SizedBox(width: AppSizes.paddingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              AnimatedCounter(
                value: valor,
                formatter: Formatador.moeda,
                style: TextStyle(
                  color: cor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosIndicador() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL, vertical: AppSizes.paddingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _textoFiltrosAtivos,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _limparFiltros,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Limpar'),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.paddingL),
      itemCount: _lancamentosFiltrados.length + (_temMaisItens ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _lancamentosFiltrados.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.paddingL),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final item = _lancamentosFiltrados[index];
        return _LancamentoCard(
          item: item,
          onRefresh: _carregarLancamentos,
        );
      },
    );
  }

  bool get _filtrosAtivos {
    return filtroTipo != 'Todos' ||
        filtroCategoria != 'Todas' ||
        dataInicio != null ||
        dataFim != null ||
        _ordenacaoAtual != Ordenacao.dataDesc;
  }

  String get _textoFiltrosAtivos {
    List<String> filtros = [];

    if (filtroTipo != 'Todos') filtros.add('Tipo: $filtroTipo');
    if (filtroCategoria != 'Todas') filtros.add('Categoria: $filtroCategoria');
    if (dataInicio != null) {
      filtros.add('De: ${DateFormat('dd/MM').format(dataInicio!)}');
    }
    if (dataFim != null) {
      filtros.add('Até: ${DateFormat('dd/MM').format(dataFim!)}');
    }

    switch (_ordenacaoAtual) {
      case Ordenacao.dataDesc:
        filtros.add('Ordenado por: Data (recente)');
        break;
      case Ordenacao.dataAsc:
        filtros.add('Ordenado por: Data (antigo)');
        break;
      case Ordenacao.valorDesc:
        filtros.add('Ordenado por: Maior valor');
        break;
      case Ordenacao.valorAsc:
        filtros.add('Ordenado por: Menor valor');
        break;
    }

    return filtros.join(' • ');
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.receipt,
      message: 'Nenhum lançamento cadastrado',
      buttonText: 'Adicionar lançamento',
      onButtonPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NovaTransacaoScreen(),
          ),
        );
        if (result == true) {
          await _carregarLancamentos();
        }
      },
    );
  }

  Widget _buildSemResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.filter_alt,
              size: AppSizes.iconXL, color: AppColors.textHint),
          const SizedBox(height: AppSizes.paddingL),
          const Text(
            'Nenhum resultado com os filtros atuais',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.paddingS),
          GradientButton(
            text: 'Limpar filtros',
            icon: Icons.clear,
            onPressed: _limparFiltros,
          ),
        ],
      ),
    );
  }

  void _mostrarOpcoesOrdenacao() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordenar por',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.paddingXL),
              _buildOrdenacaoItem(
                'Data (mais recente)',
                Ordenacao.dataDesc,
                Icons.calendar_today,
              ),
              _buildOrdenacaoItem(
                'Data (mais antigo)',
                Ordenacao.dataAsc,
                Icons.calendar_today,
              ),
              _buildOrdenacaoItem(
                'Maior valor',
                Ordenacao.valorDesc,
                Icons.trending_up,
              ),
              _buildOrdenacaoItem(
                'Menor valor',
                Ordenacao.valorAsc,
                Icons.trending_down,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdenacaoItem(String titulo, Ordenacao valor, IconData icone) {
    return ListTile(
      leading: Icon(
        icone,
        color: _ordenacaoAtual == valor ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          color: _ordenacaoAtual == valor ? AppColors.primary : Colors.black,
          fontWeight:
              _ordenacaoAtual == valor ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: _ordenacaoAtual == valor
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          _ordenacaoAtual = valor;
          _lancamentosFiltradosCache = null;
        });
        Navigator.pop(context);
      },
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(AppSizes.paddingXL),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.paddingXL),
                    const Text('Tipo',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSizes.paddingS),
                    Wrap(
                      spacing: AppSizes.paddingS,
                      children: tipos.map((tipo) {
                        return FilterChip(
                          label: Text(tipo),
                          selected: filtroTipo == tipo,
                          onSelected: (_) {
                            setStateModal(() {
                              filtroTipo = tipo;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.paddingL),
                    const Text('Categoria',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSizes.paddingS),
                    Wrap(
                      spacing: AppSizes.paddingS,
                      children: categorias.map((categoria) {
                        return FilterChip(
                          label: Text(categoria),
                          selected: filtroCategoria == categoria,
                          onSelected: (_) {
                            setStateModal(() {
                              filtroCategoria = categoria;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.paddingL),
                    const Text('Período',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSizes.paddingS),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDataPicker(
                            'Data inicial',
                            dataInicio,
                            (date) => setStateModal(() => dataInicio = date),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingS),
                        Expanded(
                          child: _buildDataPicker(
                            'Data final',
                            dataFim,
                            (date) => setStateModal(() => dataFim = date),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingXL),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setStateModal(() {
                                filtroTipo = 'Todos';
                                filtroCategoria = 'Todas';
                                dataInicio = null;
                                dataFim = null;
                              });
                            },
                            child: const Text('Limpar'),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingM),
                        Expanded(
                          child: GradientButton(
                            text: 'Aplicar',
                            onPressed: () {
                              _aplicarFiltros();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDataPicker(
      String label, DateTime? data, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: data ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('pt', 'BR'),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingL,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: AppSizes.iconXS),
            const SizedBox(width: AppSizes.paddingS),
            Expanded(
              child: Text(
                data == null ? label : DateFormat('dd/MM/yyyy').format(data),
                style: TextStyle(
                  color: data == null ? AppColors.textHint : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LancamentoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRefresh;

  const _LancamentoCard({
    required this.item,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tipoLower = item['tipo']?.toString().toLowerCase() ?? '';
    final isReceita = tipoLower == 'receita' || tipoLower == 'receitas';
    final cor = isReceita ? AppColors.success : AppColors.error;
    final icone = isReceita ? Icons.arrow_upward : Icons.arrow_downward;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: ModernCard(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditarTransacaoScreen(lancamento: item),
            ),
          );
          if (result == true) {
            onRefresh.call();
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
              child: Icon(icone, color: cor, size: 24),
            ),
            const SizedBox(width: AppSizes.paddingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['descricao'] ?? 'Sem descrição',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        child: Text(
                          item['categoria'] ?? 'Outros',
                          style: TextStyle(
                            fontSize: 10,
                            color: cor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS),
                      Text(
                        Formatador.data(DateTime.parse(item['data'])),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedCounter(
              value: item['valor']?.toDouble() ?? 0,
              formatter: Formatador.moeda,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LancamentosSkeleton extends StatelessWidget {
  const _LancamentosSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(AppSizes.paddingL),
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(
                    child: Container(
                      width: 100,
                      height: 40,
                      color: Colors.white,
                    ),
                  ),
                  SkeletonLoader(
                    child: Container(
                      width: 80,
                      height: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingL),
              Row(
                children: [
                  Expanded(
                    child: SkeletonLoader(
                      child: Container(
                        height: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: SkeletonLoader(
                      child: Container(
                        height: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
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
              );
            },
          ),
        ),
      ],
    );
  }
}
