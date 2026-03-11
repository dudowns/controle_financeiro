// lib/repositories/lancamento_repository.dart

import '../database/db_helper.dart';
import '../models/lancamento_model.dart';

class LancamentoRepository {
  final DBHelper _dbHelper = DBHelper();

  // ========== CONSTANTES ==========
  static const String tabelaLancamentos = DBHelper.tabelaLancamentos;

  // ========== MÉTODOS CRUD ==========

  /// Busca todos os lançamentos
  Future<List<Map<String, dynamic>>> getAllLancamentos() async {
    return await _dbHelper.getAllLancamentos();
  }

  /// Busca lançamentos como modelos (para usar com type safety)
  Future<List<Lancamento>> getAllLancamentosModel() async {
    final dados = await _dbHelper.getAllLancamentos();
    return dados.map((json) => Lancamento.fromJson(json)).toList();
  }

  /// Busca um lançamento pelo ID
  Future<Map<String, dynamic>?> getLancamentoById(int id) async {
    return await _dbHelper.getLancamentoById(id);
  }

  /// Busca um lançamento como modelo
  Future<Lancamento?> getLancamentoModelById(int id) async {
    final dados = await _dbHelper.getLancamentoById(id);
    if (dados == null) return null;
    return Lancamento.fromJson(dados);
  }

  /// Insere um novo lançamento
  Future<int> insertLancamento(Map<String, dynamic> lancamento) async {
    return await _dbHelper.insertLancamento(lancamento);
  }

  /// Insere um lançamento a partir do modelo
  Future<int> insertLancamentoModel(Lancamento lancamento) async {
    return await _dbHelper.insertLancamento(lancamento.toJson());
  }

  /// Atualiza um lançamento existente
  Future<int> updateLancamento(Map<String, dynamic> lancamento) async {
    return await _dbHelper.updateLancamento(lancamento);
  }

  /// Atualiza um lançamento a partir do modelo
  Future<int> updateLancamentoModel(Lancamento lancamento) async {
    if (lancamento.id == null) throw Exception('ID não pode ser nulo');
    return await _dbHelper.updateLancamento(lancamento.toJson());
  }

  /// Deleta um lançamento
  Future<int> deleteLancamento(int id) async {
    return await _dbHelper.deleteLancamento(id);
  }

  // ========== MÉTODOS ESPECÍFICOS ==========

  /// Busca lançamentos por período
  Future<List<Lancamento>> getLancamentosByPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    final db = await _dbHelper.database;
    final resultados = await db.query(
      tabelaLancamentos,
      where: 'date(data) BETWEEN date(?) AND date(?)',
      whereArgs: [inicio.toIso8601String(), fim.toIso8601String()],
      orderBy: 'data DESC',
    );
    return resultados.map((json) => Lancamento.fromJson(json)).toList();
  }

  /// Busca lançamentos por tipo
  Future<List<Lancamento>> getLancamentosByTipo(TipoLancamento tipo) async {
    final db = await _dbHelper.database;
    final resultados = await db.query(
      tabelaLancamentos,
      where: 'tipo = ?',
      whereArgs: [tipo.nome],
      orderBy: 'data DESC',
    );
    return resultados.map((json) => Lancamento.fromJson(json)).toList();
  }

  /// Busca lançamentos por categoria
  Future<List<Lancamento>> getLancamentosByCategoria(String categoria) async {
    final db = await _dbHelper.database;
    final resultados = await db.query(
      tabelaLancamentos,
      where: 'categoria = ?',
      whereArgs: [categoria],
      orderBy: 'data DESC',
    );
    return resultados.map((json) => Lancamento.fromJson(json)).toList();
  }

  /// Busca lançamentos paginados
  Future<List<Map<String, dynamic>>> getLancamentosPaginados({
    required int pagina,
    int porPagina = 20,
    String? tipo,
    String? categoria,
    DateTime? dataInicio,
    DateTime? dataFim,
    OrdemLancamento ordem = OrdemLancamento.dataDesc,
  }) async {
    return await _dbHelper.getLancamentosPaginados(
      pagina: pagina,
      porPagina: porPagina,
      tipo: tipo,
      categoria: categoria,
      dataInicio: dataInicio,
      dataFim: dataFim,
      ordem: ordem,
    );
  }

  // ========== MÉTODOS DE ESTATÍSTICAS ==========

  /// Calcula resumo do mês
  Future<Map<String, dynamic>> getResumoDoMes(DateTime mes) async {
    final primeiroDia = DateTime(mes.year, mes.month, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0);

    final lancamentos = await getLancamentosByPeriodo(primeiroDia, ultimoDia);

    double receitas = 0;
    double despesas = 0;
    final Map<String, double> gastosPorCategoria = {};

    for (var l in lancamentos) {
      if (l.tipo == TipoLancamento.receita) {
        receitas += l.valor;
      } else {
        despesas += l.valor;
        gastosPorCategoria[l.categoria] =
            (gastosPorCategoria[l.categoria] ?? 0) + l.valor;
      }
    }

    // Ordenar categorias por valor (maior para menor)
    final categoriasOrdenadas = Map.fromEntries(
        gastosPorCategoria.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));

    return {
      'receitas': receitas,
      'despesas': despesas,
      'saldo': receitas - despesas,
      'totalLancamentos': lancamentos.length,
      'gastosPorCategoria': categoriasOrdenadas,
    };
  }

  /// Calcula estatísticas gerais
  Future<Map<String, dynamic>> getEstatisticasGerais() async {
    final lancamentos = await getAllLancamentosModel();

    double totalReceitas = 0;
    double totalDespesas = 0;
    final Map<String, double> gastosPorCategoria = {};
    final Map<String, double> receitasPorCategoria = {};

    for (var l in lancamentos) {
      if (l.tipo == TipoLancamento.receita) {
        totalReceitas += l.valor;
        receitasPorCategoria[l.categoria] =
            (receitasPorCategoria[l.categoria] ?? 0) + l.valor;
      } else {
        totalDespesas += l.valor;
        gastosPorCategoria[l.categoria] =
            (gastosPorCategoria[l.categoria] ?? 0) + l.valor;
      }
    }

    return {
      'totalReceitas': totalReceitas,
      'totalDespesas': totalDespesas,
      'saldoTotal': totalReceitas - totalDespesas,
      'gastosPorCategoria': gastosPorCategoria,
      'receitasPorCategoria': receitasPorCategoria,
      'totalLancamentos': lancamentos.length,
    };
  }

  /// Insere vários lançamentos em lote
  Future<void> insertLancamentosEmLote(
      List<Map<String, dynamic>> lancamentos) async {
    await _dbHelper.insertLancamentosEmLote(lancamentos);
  }

  /// Deleta vários lançamentos em lote
  Future<void> deleteEmLote(List<int> ids) async {
    await _dbHelper.deleteEmLote(tabelaLancamentos, ids);
  }
}
