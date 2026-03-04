// lib/screens/investimentos_tabs.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/yahoo_finance_service.dart';
import '../services/notification_service.dart';
import '../services/performance_service.dart';
import 'detalhes_ativo.dart';
import 'grafico_ativo.dart';
import 'proventos.dart';
import 'editar_investimento.dart';
import 'adicionar_investimento.dart'; // 🔥 NOVO IMPORT!
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'analise_screen.dart';
import 'renda_fixa_dialog.dart';
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

class InvestimentosTabsScreen extends StatefulWidget {
  const InvestimentosTabsScreen({super.key});

  @override
  State<InvestimentosTabsScreen> createState() =>
      _InvestimentosTabsScreenState();
}

class _InvestimentosTabsScreenState extends State<InvestimentosTabsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  final DBHelper db = DBHelper();
  List<Map<String, dynamic>> investimentos = [];
  List<Map<String, dynamic>> proventos = [];
  List<Map<String, dynamic>> rendaFixa = [];

  bool carregando = true;
  bool _primeiraCarga = true;
  bool atualizando = false;

  double patrimonioTotal = 0;
  double valorInvestido = 0;
  double ganhoCapital = 0;
  double dividendosRecebidos = 0;
  double proventos12Meses = 0;
  final Map<String, double> valorPorTipo = {};

  // CORES COM VERDE VIVO (0xFF4CAF50)
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

  Future<void> carregarDados() async {
    PerformanceService.start('carregarInvestimentos');

    setState(() => carregando = true);

    try {
      investimentos = await db.getAllInvestimentos();
    } catch (e) {
      // Error loading investments
    }
    try {
      proventos = await db.getAllProventos();
    } catch (e) {
      // Error loading proventos
    }
    try {
      rendaFixa = await db.getAllRendaFixa();
    } catch (e) {
      // Error loading renda fixa
    }
    _calcularEstatisticas();

    PerformanceService.stop('carregarInvestimentos');

    setState(() {
      carregando = false;
      _primeiraCarga = false;
    });
  }

  void _calcularEstatisticas() {
    patrimonioTotal = 0;
    valorInvestido = 0;
    dividendosRecebidos = 0;
    proventos12Meses = 0;
    valorPorTipo.clear();

    final agora = DateTime.now();
    final umAnoAtras = DateTime(agora.year - 1, agora.month, agora.day);

    for (var item in investimentos) {
      final precoAtual = (item['preco_atual'] ?? item['preco_medio']) as num;
      final quantidade = (item['quantidade'] ?? 0) as num;
      final precoMedio = (item['preco_medio'] ?? 0) as num;

      final valorAtual = precoAtual.toDouble() * quantidade.toDouble();
      final investido = precoMedio.toDouble() * quantidade.toDouble();

      patrimonioTotal += valorAtual;
      valorInvestido += investido;

      final tipo = item['tipo'] as String? ?? 'OUTROS';
      valorPorTipo[tipo] = (valorPorTipo[tipo] ?? 0) + valorAtual;
    }

    for (var item in rendaFixa) {
      final valorFinal = item['valor_final'] ?? item['valor'];
      patrimonioTotal += valorFinal;
      valorInvestido += (item['valor'] ?? 0);
      valorPorTipo['RENDA_FIXA'] =
          (valorPorTipo['RENDA_FIXA'] ?? 0) + valorFinal;
    }

    for (var p in proventos) {
      final dataString = p['data_pagamento'] as String? ?? '';
      final valor = (p['total_recebido'] ?? 0) as num;
      try {
        final data = DateTime.parse(dataString);
        final valorDouble = valor.toDouble();
        dividendosRecebidos += valorDouble;
        if (data.isAfter(umAnoAtras)) proventos12Meses += valorDouble;
      } catch (e) {}
    }

    ganhoCapital = patrimonioTotal - valorInvestido;
  }

  Map<String, Map<String, double>> _calcularEvolucaoMensalReal() {
    Map<String, Map<String, double>> evolucao = {};

    for (var item in investimentos) {
      try {
        DateTime dataCompra = DateTime.parse(item['data_compra']);
        String mesAno = DateFormat('MMM/yy').format(dataCompra);

        double valorAtual =
            (item['preco_atual'] ?? item['preco_medio']) * item['quantidade'];
        double valorInvestido = item['preco_medio'] * item['quantidade'];

        if (!evolucao.containsKey(mesAno)) {
          evolucao[mesAno] = {
            'patrimonio': 0,
            'investido': 0,
          };
        }

        evolucao[mesAno]!['patrimonio'] =
            (evolucao[mesAno]!['patrimonio'] ?? 0) + valorAtual;
        evolucao[mesAno]!['investido'] =
            (evolucao[mesAno]!['investido'] ?? 0) + valorInvestido;
      } catch (e) {}
    }

    for (var item in rendaFixa) {
      try {
        DateTime dataAplicacao = DateTime.parse(item['data_aplicacao']);
        String mesAno = DateFormat('MMM/yy').format(dataAplicacao);

        double valorAtual = item['valor_final'] ?? item['valor'];
        double valorInvestido = item['valor'] ?? 0;

        if (!evolucao.containsKey(mesAno)) {
          evolucao[mesAno] = {
            'patrimonio': 0,
            'investido': 0,
          };
        }

        evolucao[mesAno]!['patrimonio'] =
            (evolucao[mesAno]!['patrimonio'] ?? 0) + valorAtual;
        evolucao[mesAno]!['investido'] =
            (evolucao[mesAno]!['investido'] ?? 0) + valorInvestido;
      } catch (e) {}
    }

    return evolucao;
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
      'dez': 12
    };
    return meses[mesTexto.toLowerCase()] ?? 1;
  }

  Future<void> _atualizarPrecos() async {
    setState(() => atualizando = true);
    int atualizados = 0, comErro = 0;
    final service = YahooFinanceService();

    for (var item in investimentos) {
      try {
        final preco = await service.getPrecoAtual(item['ticker']);
        if (preco != null && preco > 0) {
          await db.updatePrecoAtual(item['id'], preco);
          atualizados++;
        } else {
          comErro++;
        }
      } catch (e) {
        comErro++;
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

  String _formatarValor(double valor) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(valor);

  String _formatarCompacto(double valor) {
    if (valor >= 1000000) return "R\$ ${(valor / 1000000).toStringAsFixed(1)}M";
    if (valor >= 1000) return "R\$ ${(valor / 1000).toStringAsFixed(0)}k";
    return _formatarValor(valor);
  }

  String _formatarPercentual(double valor) =>
      '${valor.toStringAsFixed(2).replaceAll('.', ',')}%';

  String _formatarQuantidade(double valor) => valor.toStringAsFixed(0);

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
              onSelected: (value) {
                setState(() {
                  if (value == 'ticker') {
                    investimentos
                        .sort((a, b) => a['ticker'].compareTo(b['ticker']));
                  } else if (value == 'valor') {
                    investimentos.sort((a, b) {
                      double valorA = (a['preco_atual'] ?? a['preco_medio']) *
                          a['quantidade'];
                      double valorB = (b['preco_atual'] ?? b['preco_medio']) *
                          b['quantidade'];
                      return valorB.compareTo(valorA);
                    });
                  } else if (value == 'rentabilidade') {
                    investimentos.sort((a, b) {
                      double rentA = ((a['preco_atual'] ?? a['preco_medio']) -
                              a['preco_medio']) /
                          a['preco_medio'];
                      double rentB = ((b['preco_atual'] ?? b['preco_medio']) -
                              b['preco_medio']) /
                          b['preco_medio'];
                      return rentB.compareTo(rentA);
                    });
                  }
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                    value: 'ticker', child: Text('Ordenar por ticker')),
                PopupMenuItem(value: 'valor', child: Text('Maior valor')),
                PopupMenuItem(
                    value: 'rentabilidade',
                    child: Text('Melhor rentabilidade')),
              ],
            ),
            IconButton(
              icon: atualizando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
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
                      AppColors.secondaryPurple
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
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

  void _mostrarMenuCompraVenda() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('O que deseja fazer?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.trending_up, color: Colors.blue)),
                title: const Text('Comprar Ações/FIIs',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    const Text('Adicionar novo investimento em renda variável'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirDialogAdicionar(); // ✅ AGORA FUNCIONA!
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.savings, color: Colors.teal)),
                title: const Text('Comprar Renda Fixa',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('CDB, LCI, Tesouro, etc'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirDialogRendaFixa();
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.trending_down, color: Colors.red)),
                title: const Text('Vender Ativo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    const Text('Registrar venda de um investimento existente'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarListaAtivosParaVenda();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
            ],
          ),
        );
      },
    );
  }

  void _mostrarListaAtivosParaVenda() {
    if (investimentos.isEmpty && rendaFixa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhum ativo disponível para venda'),
          backgroundColor: Colors.orange));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Selecione o ativo para vender',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: investimentos.length + rendaFixa.length,
                      itemBuilder: (context, index) {
                        if (index < investimentos.length) {
                          final item = investimentos[index];
                          final cor = coresPorTipo[item['tipo']] ?? Colors.grey;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: cor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(
                                      item['tipo'] == 'FII'
                                          ? Icons.apartment
                                          : Icons.trending_up,
                                      color: cor,
                                      size: 20)),
                              title: Text(item['ticker']),
                              subtitle: Text(
                                  '${item['quantidade'].toStringAsFixed(0)} cotas • Preço médio: ${_formatarValor(item['preco_medio'])}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                _abrirDialogVenda(item, tipo: 'variavel');
                              },
                            ),
                          );
                        } else {
                          final item = rendaFixa[index - investimentos.length];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.savings,
                                      color: Colors.teal, size: 20)),
                              title: Text(item['nome']),
                              subtitle: Text(
                                  '${item['tipo_renda']} • Valor: ${_formatarValor(item['valor'])}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context);
                                _abrirDialogVenda(item, tipo: 'fixa');
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _abrirDialogVenda(Map<String, dynamic> item,
      {required String tipo}) async {
    if (tipo == 'variavel') {
    } else {}
  }

  void _abrirDialogRendaFixa() {
    showDialog(
      context: context,
      builder: (context) => RendaFixaDialog(onSalvar: _salvarRendaFixa),
    );
  }

  Future<void> _salvarRendaFixa(Map<String, dynamic> dados) async {
    try {
      await db.insertRendaFixa(dados);
      final dataVencimento = DateTime.parse(dados['data_vencimento']);
      final rendimento = dados['rendimento_liquido'] ?? 0;
      if (rendimento > 0) {
        await db.insertProvento({
          'ticker': dados['nome'],
          'tipo_provento': 'Renda Fixa',
          'valor_por_cota': rendimento,
          'data_pagamento': dataVencimento.toIso8601String(),
          'total_recebido': rendimento,
          'sync_automatico': 1,
        });
      }
      await carregarDados();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Renda Fixa adicionada! Provento agendado para ${DateFormat('dd/MM/yyyy').format(dataVencimento)}'),
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

  void _editarRendaFixa(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Renda Fixa'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
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
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await db.deleteRendaFixa(item['id']);
              await carregarDados();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Renda Fixa excluída!'),
                      backgroundColor: Colors.green),
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

  Future<double> _calcularRendimentoDiarioAproximado(
      Map<String, dynamic> item) async {
    try {
      DateTime hoje = DateTime.now();
      DateTime amanha = hoje.add(const Duration(days: 1));

      double valorHoje = db.calcularValorEmData(item, hoje);
      double valorAmanha = db.calcularValorEmData(item, amanha);

      return valorAmanha - valorHoje;
    } catch (e) {
      return 0;
    }
  }

  void _mostrarDetalhesRendaFixa(Map<String, dynamic> item) {
    DateTime dataAplicacao = DateTime.parse(item['data_aplicacao']);
    DateTime dataVencimento = DateTime.parse(item['data_vencimento']);
    DateTime hoje = DateTime.now();

    double valorHoje = db.calcularValorEmData(item, hoje);
    double rendimentoHoje = valorHoje - (item['valor'] ?? 0);
    double percentualHoje = (rendimentoHoje / (item['valor'] ?? 1)) * 100;

    int diasPassados = hoje.difference(dataAplicacao).inDays;
    int diasRestantes = dataVencimento.difference(hoje).inDays;
    int diasTotal = dataVencimento.difference(dataAplicacao).inDays;
    double progresso = diasTotal > 0 ? diasPassados / diasTotal : 0;

    List<Map<String, dynamic>> evolucao = db.calcularEvolucaoDiaria(item);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.savings, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nome'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item['tipo_renda'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VALOR HOJE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatarValor(valorHoje),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '+${_formatarValor(rendimentoHoje)} (${percentualHoje.toStringAsFixed(2)}%)',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'APLICAÇÃO',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatarValor(item['valor']),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progresso: $diasPassados de $diasTotal dias',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${(progresso * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progresso,
                              backgroundColor: Colors.grey[200],
                              color: Colors.teal,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        children: [
                          _buildInfoCard(
                            'Aplicação',
                            DateFormat('dd/MM/yyyy').format(dataAplicacao),
                            Icons.calendar_today,
                          ),
                          _buildInfoCard(
                            'Vencimento',
                            DateFormat('dd/MM/yyyy').format(dataVencimento),
                            Icons.event,
                          ),
                          _buildInfoCard(
                            'Dias Restantes',
                            '$diasRestantes',
                            Icons.timer,
                          ),
                          _buildInfoCard(
                            'Taxa',
                            '${item['taxa']}%',
                            Icons.percent,
                          ),
                          _buildInfoCard(
                            'Liquidez',
                            item['liquidez'] ?? 'N/A',
                            Icons.water_drop,
                          ),
                          _buildInfoCard(
                            'Indexador',
                            item['indexador'] ?? 'N/A',
                            Icons.trending_up,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '📈 Evolução Diária',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: evolucao.length,
                          itemBuilder: (context, index) {
                            final ponto = evolucao[index];
                            DateTime data = DateTime.parse(ponto['data']);
                            return Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ponto['hoje'] == true
                                    ? _profitBg
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ponto['hoje'] == true
                                      ? _profitText
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('dd/MM').format(data),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatarValor(ponto['valor']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: ponto['hoje'] == true
                                          ? _profitText
                                          : Colors.black,
                                      fontWeight: ponto['hoje'] == true
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetalheLinha(
                              'Rendimento Bruto',
                              _formatarValor(item['rendimento_bruto'] ?? 0),
                            ),
                            if (item['iof'] != null && item['iof'] > 0)
                              _buildDetalheLinha(
                                'IOF',
                                _formatarValor(item['iof']),
                              ),
                            if (item['ir'] != null && item['ir'] > 0)
                              _buildDetalheLinha(
                                'IR',
                                _formatarValor(item['ir']),
                              ),
                            const Divider(height: 16),
                            _buildDetalheLinha(
                              'Rendimento Líquido',
                              _formatarValor(item['rendimento_liquido'] ?? 0),
                              cor: _profitText,
                              isTotal: true,
                            ),
                            _buildDetalheLinha(
                              'Valor Final Projetado',
                              _formatarValor(
                                  item['valor_final'] ?? item['valor']),
                              cor: Colors.teal,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.teal),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDetalheLinha(String label, String valor,
      {Color? cor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(valor,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: cor)),
        ],
      ),
    );
  }

  Widget _buildCarteiraTab() {
    if (investimentos.isEmpty && rendaFixa.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.trending_up,
                  size: 64, color: AppColors.primaryPurple),
            ),
            const SizedBox(height: 24),
            const Text('Nenhum investimento',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2F))),
            const SizedBox(height: 8),
            Text('Toque no + para adicionar seu primeiro ativo',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderTurbinado(),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < investimentos.length) {
                return _buildAtivoCardTurbinado(investimentos[index]);
              } else {
                return _buildRendaFixaCard(
                    rendaFixa[index - investimentos.length]);
              }
            }, childCount: investimentos.length + rendaFixa.length),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
      ],
    );
  }

  Widget _buildHeaderTurbinado() {
    double totalInvestido = 0, totalAtual = 0;
    for (var item in investimentos) {
      totalInvestido += item['preco_medio'] * item['quantidade'];
      totalAtual +=
          (item['preco_atual'] ?? item['preco_medio']) * item['quantidade'];
    }
    for (var item in rendaFixa) {
      totalInvestido += item['valor'] ?? 0;
      totalAtual += item['valor_final'] ?? item['valor'] ?? 0;
    }
    double rentabilidade = totalInvestido > 0
        ? ((totalAtual - totalInvestido) / totalInvestido) * 100
        : 0;

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.secondaryPurple]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
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
                const Text('PATRIMÔNIO',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white70, letterSpacing: 1)),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        '${investimentos.length + rendaFixa.length} ativos',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
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
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: rentabilidade >= 0
                          ? _profitBg.withValues(alpha: 0.2)
                          : _lossBg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(
                          rentabilidade >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: rentabilidade >= 0 ? _profitText : _lossText),
                      const SizedBox(width: 4),
                      Text(
                          '${rentabilidade >= 0 ? '+' : ''}${rentabilidade.toStringAsFixed(2)}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: rentabilidade >= 0
                                  ? _profitText
                                  : _lossText)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard('Investido', totalInvestido,
                        Icons.account_balance_wallet)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard('Rendimento',
                        totalAtual - totalInvestido, Icons.trending_up,
                        cor: (totalAtual - totalInvestido) >= 0
                            ? _profitText
                            : _lossText)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard('Dividendos', dividendosRecebidos,
                        Icons.monetization_on,
                        cor: _profitText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, double valor, IconData icone,
      {Color? cor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12)),
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
                color: cor ?? Colors.white),
          ),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildAtivoCardTurbinado(Map<String, dynamic> item) {
    final cor = coresPorTipo[item['tipo']] ?? Colors.grey;
    final precoAtual = item['preco_atual'] ?? item['preco_medio'];
    final quantidade = item['quantidade'];
    final totalInvestido = item['preco_medio'] * quantidade;
    final valorAtual = precoAtual * quantidade;
    final rentabilidade =
        ((valorAtual - totalInvestido) / totalInvestido) * 100;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(
          milliseconds: 300 + (((item['id'] ?? 0) as num).toInt() % 300)),
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
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetalhesAtivoScreen(ativo: item)))
                .then((_) => carregarDados()),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                          item['tipo'] == 'FII'
                              ? Icons.apartment
                              : item['tipo'] == 'CRIPTO'
                                  ? Icons.currency_bitcoin
                                  : Icons.trending_up,
                          color: cor,
                          size: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item['ticker'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(item['tipo'],
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cor,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${_formatarQuantidade(quantidade)} cotas',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedCounter(
                            value: precoAtual,
                            formatter: _formatarValor,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: rentabilidade >= 0 ? _profitBg : _lossBg,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${rentabilidade >= 0 ? '+' : ''}${rentabilidade.toStringAsFixed(2)}%',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: rentabilidade >= 0
                                        ? _profitText
                                        : _lossText)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppColors.primaryPurple),
                        onPressed: () async {
                          final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditarInvestimentoScreen(
                                      investimento: item)));
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

  Widget _buildRendaFixaCard(Map<String, dynamic> item) {
    final rendimentoLiquido = (item['rendimento_liquido'] ?? 0).toDouble();
    final valorFinal = (item['valor_final'] ?? item['valor'] ?? 0).toDouble();

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(
          milliseconds: 300 + (((item['id'] ?? 0) as num).toInt() % 300)),
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
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
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
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.savings,
                          color: Colors.teal, size: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item['nome'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(item['tipo_renda'],
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            'Aplicação: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['data_aplicacao']))}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        Text(
                            'Vencimento: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['data_vencimento']))}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange[700])),
                        if (item['liquidez'] != null)
                          Text('Liquidez: ${item['liquidez']}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.blue[600])),
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
                          '+${_formatarValor(rendimentoLiquido)} '
                          '(${((rendimentoLiquido / item['valor']) * 100).toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            color: _profitText,
                          ),
                        ),
                      FutureBuilder<double>(
                        future: _calcularRendimentoDiarioAproximado(item),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! > 0) {
                            return Text(
                              '~ ${_formatarValor(snapshot.data!)}/dia',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[600],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18, color: Color(0xFF6A1B9A)),
                            onPressed: () => _editarRendaFixa(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
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

  Widget _buildAlocacaoExpansivel() {
    Map<String, List<Map<String, dynamic>>> investimentosPorTipo = {};
    for (var item in investimentos) {
      String tipo = item['tipo'] ?? 'OUTROS';
      if (!investimentosPorTipo.containsKey(tipo)) {
        investimentosPorTipo[tipo] = [];
      }
      investimentosPorTipo[tipo]!.add(item);
    }
    if (rendaFixa.isNotEmpty) {
      investimentosPorTipo['RENDA_FIXA'] = rendaFixa
          .map((rf) => {
                'ticker': rf['nome'],
                'tipo': 'RENDA_FIXA',
                'quantidade': 1,
                'preco_medio': rf['valor'],
                'preco_atual': rf['valor_final'] ?? rf['valor'],
                'data_compra': rf['data_aplicacao'],
                'taxa': rf['taxa'],
                'vencimento': rf['data_vencimento'],
                'rendimento': rf['rendimento_liquido'],
              })
          .toList();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 ALOCAÇÃO POR ATIVO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (investimentosPorTipo.containsKey('ACAO'))
              _buildExpansionCategoria('📈 AÇÕES', Icons.trending_up,
                  Colors.blue, investimentosPorTipo['ACAO']!),
            if (investimentosPorTipo.containsKey('FII'))
              _buildExpansionCategoria('🏢 FIIs', Icons.apartment, Colors.green,
                  investimentosPorTipo['FII']!),
            if (investimentosPorTipo.containsKey('RENDA_FIXA'))
              _buildExpansionCategoria('💰 RENDA FIXA', Icons.savings,
                  Colors.teal, investimentosPorTipo['RENDA_FIXA']!),
            if (investimentosPorTipo.containsKey('CRIPTO'))
              _buildExpansionCategoria('🪙 CRIPTO', Icons.currency_bitcoin,
                  Colors.amber, investimentosPorTipo['CRIPTO']!),
            if (investimentosPorTipo.containsKey('ETF'))
              _buildExpansionCategoria('📊 ETFs', Icons.show_chart,
                  Colors.purple, investimentosPorTipo['ETF']!),
            if (investimentosPorTipo.containsKey('BDR'))
              _buildExpansionCategoria('🌎 BDRs', Icons.public, Colors.teal,
                  investimentosPorTipo['BDR']!),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionCategoria(String titulo, IconData icone, Color cor,
      List<Map<String, dynamic>> ativos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icone, color: cor, size: 20)),
          title: Text(titulo,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: cor)),
          subtitle: Text(
              '${ativos.length} ativos • Total: ${_formatarValor(_calcularTotalCategoria(ativos))}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children:
              ativos.map((ativo) => _buildAtivoLinha(ativo, cor)).toList(),
        ),
      ),
    );
  }

  double _calcularTotalCategoria(List<Map<String, dynamic>> ativos) {
    return ativos.fold(
        0,
        (sum, item) =>
            sum +
            (item['quantidade'] *
                (item['preco_atual'] ?? item['preco_medio'])));
  }

  Widget _buildAtivoLinha(Map<String, dynamic> ativo, Color cor) {
    final quantidade = ativo['quantidade'];
    final precoAtual = ativo['preco_atual'] ?? ativo['preco_medio'];
    final valorTotal = quantidade * precoAtual;

    double rentabilidade = 0;
    if (ativo['tipo'] == 'RENDA_FIXA') {
      rentabilidade = ((ativo['preco_atual'] - ativo['preco_medio']) /
              ativo['preco_medio']) *
          100;
    } else {
      rentabilidade =
          ((precoAtual - ativo['preco_medio']) / ativo['preco_medio']) * 100;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1))),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(ativo['ticker'] ?? 'Renda Fixa',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(
                  '${quantidade.toStringAsFixed(0)} ${quantidade == 1 ? 'operação' : 'operações'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
          Expanded(
              flex: 2,
              child: Text(_formatarValor(valorTotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.right)),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: rentabilidade >= 0 ? _profitBg : _lossBg,
                borderRadius: BorderRadius.circular(8)),
            child: Text(
                '${rentabilidade >= 0 ? '+' : ''}${rentabilidade.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 10,
                    color: rentabilidade >= 0 ? _profitText : _lossText,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
                colors: [AppColors.primaryPurple, AppColors.secondaryPurple])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PATRIMÔNIO TOTAL',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(_formatarValor(patrimonioTotal),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: variacaoPercentual >= 0
                          ? _profitBg.withValues(alpha: 0.2)
                          : _lossBg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(
                          variacaoPercentual >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: variacaoPercentual >= 0
                              ? _profitText
                              : _lossText),
                      const SizedBox(width: 4),
                      Text(
                          '${variacaoPercentual >= 0 ? '+' : ''}${_formatarPercentual(variacaoPercentual)}',
                          style: TextStyle(
                              color: variacaoPercentual >= 0
                                  ? _profitText
                                  : _lossText,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('Investido: ${_formatarValor(valorInvestido)}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardLucro() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LUCRO TOTAL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Column(children: [
                  Text('Ganho Capital',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  AnimatedCounter(
                    value: ganhoCapital,
                    formatter: _formatarValor,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ganhoCapital >= 0 ? _profitText : _lossText),
                  ),
                ])),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(
                    child: Column(children: [
                  Text('Dividendos',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  AnimatedCounter(
                    value: dividendosRecebidos,
                    formatter: _formatarValor,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _profitText),
                  ),
                ])),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total acumulado:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  AnimatedCounter(
                    value: ganhoCapital + dividendosRecebidos,
                    formatter: _formatarValor,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6A1B9A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  Text('PROVENTOS (12M)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  AnimatedCounter(
                    value: proventos12Meses,
                    formatter: _formatarValor,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _profitText),
                  ),
                  const SizedBox(height: 4),
                  Text('Total: ${_formatarValor(dividendosRecebidos)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.monetization_on,
                    color: AppColors.primaryPurple, size: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoEvolucao() {
    final evolucaoReal = _calcularEvolucaoMensalReal();

    if (evolucaoReal.isEmpty) {
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

    var mesesOrdenados = evolucaoReal.keys.toList()
      ..sort((a, b) {
        List<String> aParts = a.split('/');
        List<String> bParts = b.split('/');

        int aAno = int.parse('20${aParts[1]}');
        int bAno = int.parse('20${bParts[1]}');
        int aMes = _getMesNumero(aParts[0]);
        int bMes = _getMesNumero(bParts[0]);

        if (aAno != bAno) return aAno.compareTo(bAno);
        return aMes.compareTo(bMes);
      });

    List<double> valoresPatrimonio = [];
    List<double> valoresInvestido = [];

    for (var mes in mesesOrdenados) {
      valoresPatrimonio.add(evolucaoReal[mes]!['patrimonio']!);
      valoresInvestido.add(evolucaoReal[mes]!['investido']!);
    }

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
                  maxY:
                      (valoresPatrimonio.reduce((a, b) => a > b ? a : b) * 1.2),
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
                  borderData: FlBorderData(
                    show: false,
                  ),
                  gridData: const FlGridData(
                    show: false,
                  ),
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
            const Text('Resumo por Tipo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          Text(_getNomeTipo(entry.key),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_formatarPercentual(percentual),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))
                        ]),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                        value: percentual / 100,
                        backgroundColor: Colors.grey[200],
                        color: _getCorTipo(entry.key),
                        minHeight: 8),
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
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  // ✅ FUNÇÃO CORRIGIDA - AGORA USA A TELA NOVA
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
}

// ========== SKELETON LOADING ==========
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
