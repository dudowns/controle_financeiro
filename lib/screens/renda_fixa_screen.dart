// lib/screens/renda_fixa_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/renda_fixa_model.dart';
import '../services/renda_fixa_diaria.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'novo_investimento_dialog.dart';
import 'detalhes_renda_fixa.dart';

class RendaFixaScreen extends StatefulWidget {
  const RendaFixaScreen({super.key});

  @override
  State<RendaFixaScreen> createState() => _RendaFixaScreenState();
}

class _RendaFixaScreenState extends State<RendaFixaScreen> {
  final DBHelper _db = DBHelper();
  List<RendaFixaModel> _investimentos = [];
  bool _carregando = true;
  String _mensagemStatus = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _mensagemStatus = 'Carregando investimentos...';
    });

    try {
      await _db.database;

      final dados = await _db.getAllRendaFixa();
      _investimentos = dados
          .map((json) {
            try {
              return RendaFixaModel.fromJson(json);
            } catch (e) {
              debugPrint('❌ Erro ao converter renda fixa: $e');
              return null;
            }
          })
          .whereType<RendaFixaModel>()
          .toList();

      _mensagemStatus = 'Carregados ${_investimentos.length} investimentos';
    } catch (e) {
      _mensagemStatus = 'Erro: $e';
      debugPrint('❌ Erro ao carregar renda fixa: $e');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvarInvestimento(RendaFixaModel investimento) async {
    try {
      await _db.insertRendaFixa(investimento.toJson());
      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Investimento adicionado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔥 SWITCHES SEM DEFAULT - TODOS OS CASOS COBERTOS!
  Color _getCorTipo(TipoRendaFixa tipo) {
    switch (tipo) {
      case TipoRendaFixa.cdb:
        return Colors.blue;
      case TipoRendaFixa.lci:
      case TipoRendaFixa.lca:
        return Colors.green;
      case TipoRendaFixa.tesouroPrefixado:
      case TipoRendaFixa.tesouroSelic:
      case TipoRendaFixa.tesouroIPCA:
        return Colors.orange;
    }
  }

  IconData _getIconeTipo(TipoRendaFixa tipo) {
    switch (tipo) {
      case TipoRendaFixa.cdb:
        return Icons.account_balance;
      case TipoRendaFixa.lci:
      case TipoRendaFixa.lca:
        return Icons.apartment;
      case TipoRendaFixa.tesouroPrefixado:
      case TipoRendaFixa.tesouroSelic:
      case TipoRendaFixa.tesouroIPCA:
        return Icons.attach_money;
    }
  }

  String _getTipoDescricao(RendaFixaModel inv) {
    switch (inv.tipo) {
      case TipoRendaFixa.cdb:
        return 'CDB';
      case TipoRendaFixa.lci:
        return 'LCI';
      case TipoRendaFixa.lca:
        return 'LCA';
      case TipoRendaFixa.tesouroPrefixado:
        return 'Tesouro Prefixado';
      case TipoRendaFixa.tesouroSelic:
        return 'Tesouro Selic';
      case TipoRendaFixa.tesouroIPCA:
        return 'Tesouro IPCA+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renda Fixa'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_mensagemStatus),
                ],
              ),
            )
          : _investimentos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum investimento em renda fixa',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _investimentos.length,
                  itemBuilder: (context, index) {
                    final inv = _investimentos[index];
                    final valorHoje =
                        RendaFixaDiaria.calcularValorEm(inv, DateTime.now());
                    final rendimento = valorHoje - inv.valorAplicado;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCorTipo(inv.tipo).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconeTipo(inv.tipo),
                            color: _getCorTipo(inv.tipo),
                          ),
                        ),
                        title: Text(
                          inv.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getTipoDescricao(inv)} • ${DateFormat('dd/MM/yyyy').format(inv.dataVencimento)}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  rendimento >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  size: 12,
                                  color: rendimento >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CurrencyFormatter.format(rendimento),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: rendimento >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(valorHoje),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF6A1B9A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'aplicado ${CurrencyFormatter.format(inv.valorAplicado)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalhesRendaFixaScreen(investimento: inv),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => NovoInvestimentoDialog(
              onSalvar: _salvarInvestimento,
            ),
          );
        },
      ),
    );
  }
}
