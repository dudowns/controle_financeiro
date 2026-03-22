// lib/repositories/meta_repository.dart

import '../database/db_helper.dart';

class MetaRepository {
  final DBHelper _dbHelper = DBHelper();

  // ========== CONSTANTES ==========
  static const String tabelaMetas = DBHelper.tabelaMetas;
  static const String tabelaDepositosMeta = DBHelper.tabelaDepositosMeta;

  // ========== MÉTODOS DE METAS ==========

  /// Busca todas as metas
  Future<List<Map<String, dynamic>>> getAllMetas() async {
    return await _dbHelper.getAllMetas();
  }

  /// Busca uma meta pelo ID
  Future<Map<String, dynamic>?> getMetaById(int id) async {
    return await _dbHelper.getMetaById(id);
  }

  /// Insere uma nova meta
  Future<int> insertMeta(Map<String, dynamic> meta) async {
    return await _dbHelper.insertMeta(meta);
  }

  /// Atualiza uma meta existente
  Future<int> updateMeta(Map<String, dynamic> meta) async {
    return await _dbHelper.updateMeta(meta);
  }

  /// Deleta uma meta
  Future<int> deleteMeta(int id) async {
    return await _dbHelper.deleteMeta(id);
  }

  /// Atualiza o progresso de uma meta
  Future<int> atualizarProgressoMeta(int id, double valorAtual) async {
    return await _dbHelper.atualizarProgressoMeta(id, valorAtual);
  }

  /// Conclui uma meta
  Future<int> concluirMeta(int id) async {
    return await _dbHelper.concluirMeta(id);
  }

  // ========== MÉTODOS DE DEPÓSITOS ==========

  /// Busca todos os depósitos de uma meta
  Future<List<Map<String, dynamic>>> getDepositosByMetaId(int metaId) async {
    return await _dbHelper.getDepositosByMetaId(metaId);
  }

  /// Insere um novo depósito
  Future<int> insertDepositoMeta(Map<String, dynamic> deposito) async {
    return await _dbHelper.insertDepositoMeta(deposito);
  }

  /// Deleta um depósito
  Future<int> deleteDeposito(int id) async {
    return await _dbHelper.deleteDeposito(id);
  }

  /// Calcula o total de depósitos de uma meta
  Future<double> getTotalDepositosByMetaId(int metaId) async {
    return await _dbHelper.getTotalDepositosByMetaId(metaId);
  }

  // ========== MÉTODOS COMBINADOS ==========

  /// Busca uma meta completa com seus depósitos
  Future<Map<String, dynamic>?> getMetaComDepositos(int id) async {
    final meta = await _dbHelper.getMetaById(id);
    if (meta == null) return null;

    final depositos = await _dbHelper.getDepositosByMetaId(id);
    meta['depositos'] = depositos;

    return meta;
  }

  /// Busca todas as metas completas com seus depósitos
  Future<List<Map<String, dynamic>>> getAllMetasComDepositos() async {
    final metas = await _dbHelper.getAllMetas();

    for (var meta in metas) {
      final depositos = await _dbHelper.getDepositosByMetaId(meta['id']);
      meta['depositos'] = depositos;
    }

    return metas;
  }

  /// Adiciona um depósito e atualiza o progresso da meta em uma transação
  Future<bool> adicionarDepositoEAtualizarMeta({
    required int metaId,
    required double valor,
    required DateTime dataDeposito,
    String? observacao,
  }) async {
    try {
      // 1. Inserir o depósito
      await _dbHelper.insertDepositoMeta({
        'meta_id': metaId,
        'valor': valor,
        'data_deposito': dataDeposito.toIso8601String(),
        'observacao': observacao,
      });

      // 2. Buscar a meta atual
      final meta = await _dbHelper.getMetaById(metaId);
      if (meta == null) return false;

      // 3. Calcular novo valor
      final valorAtual = (meta['valor_atual'] as num).toDouble();
      final novoValor = valorAtual + valor;

      // 4. Atualizar progresso
      await _dbHelper.atualizarProgressoMeta(metaId, novoValor);

      // 5. Verificar se concluiu
      final valorObjetivo = (meta['valor_objetivo'] as num).toDouble();
      if (novoValor >= valorObjetivo) {
        await _dbHelper.concluirMeta(metaId);
      }

      return true;
    } catch (e) {
      print('❌ Erro ao adicionar depósito: $e');
      return false;
    }
  }

  /// Remove um depósito e atualiza o progresso da meta
  Future<bool> removerDepositoEAtualizarMeta(int depositoId) async {
    try {
      await _dbHelper.deleteDeposito(depositoId);
      return true;
    } catch (e) {
      print('❌ Erro ao remover depósito: $e');
      return false;
    }
  }

  // ========== MÉTODOS DE ESTATÍSTICAS ==========

  /// Retorna estatísticas das metas
  Future<Map<String, dynamic>> getEstatisticasMetas() async {
    final metas = await _dbHelper.getAllMetas();

    int totalMetas = metas.length;
    int concluidas = 0;
    int emAndamento = 0;
    int atrasadas = 0;
    double valorTotalObjetivo = 0;
    double valorTotalAcumulado = 0;

    final agora = DateTime.now();

    for (var meta in metas) {
      final objetivo = (meta['valor_objetivo'] as num).toDouble();
      final atual = (meta['valor_atual'] as num).toDouble();
      final concluida = (meta['concluida'] as int) == 1;
      final dataFim = DateTime.parse(meta['data_fim']);

      valorTotalObjetivo += objetivo;
      valorTotalAcumulado += atual;

      if (concluida) {
        concluidas++;
      } else {
        emAndamento++;
        if (dataFim.isBefore(agora)) {
          atrasadas++;
        }
      }
    }

    return {
      'totalMetas': totalMetas,
      'concluidas': concluidas,
      'emAndamento': emAndamento,
      'atrasadas': atrasadas,
      'valorTotalObjetivo': valorTotalObjetivo,
      'valorTotalAcumulado': valorTotalAcumulado,
      'progressoGeral': valorTotalObjetivo > 0
          ? (valorTotalAcumulado / valorTotalObjetivo) * 100
          : 0,
    };
  }

  /// Retorna metas em andamento (não concluídas)
  Future<List<Map<String, dynamic>>> getMetasEmAndamento() async {
    final metas = await _dbHelper.getAllMetas();
    return metas.where((meta) => (meta['concluida'] as int) == 0).toList();
  }

  /// Retorna metas concluídas
  Future<List<Map<String, dynamic>>> getMetasConcluidas() async {
    final metas = await _dbHelper.getAllMetas();
    return metas.where((meta) => (meta['concluida'] as int) == 1).toList();
  }

  /// Retorna metas atrasadas
  Future<List<Map<String, dynamic>>> getMetasAtrasadas() async {
    final metas = await _dbHelper.getAllMetas();
    final agora = DateTime.now();

    return metas.where((meta) {
      final concluida = (meta['concluida'] as int) == 1;
      if (concluida) return false;

      final dataFim = DateTime.parse(meta['data_fim']);
      return dataFim.isBefore(agora);
    }).toList();
  }
}
