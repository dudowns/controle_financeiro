// lib/repositories/renda_fixa_repository.dart

import 'package:flutter/foundation.dart'; // 🔥 IMPORT ADICIONADO para debugPrint
import '../database/db_helper.dart';
import '../models/renda_fixa_model.dart';

class RendaFixaRepository {
  final DBHelper _dbHelper = DBHelper();

  static const String tabelaRendaFixa = DBHelper.tabelaRendaFixa;

  /// Busca todos os investimentos de renda fixa
  Future<List<RendaFixaModel>> getAll() async {
    final dados = await _dbHelper.getAllRendaFixa();
    return dados
        .map((json) {
          try {
            return RendaFixaModel.fromJson(json);
          } catch (e) {
            debugPrint(
                '❌ Erro ao converter renda fixa: $e'); // ✅ AGORA FUNCIONA
            return null;
          }
        })
        .whereType<RendaFixaModel>()
        .toList();
  }

  /// Busca um investimento pelo ID
  Future<RendaFixaModel?> getById(int id) async {
    final dados = await _dbHelper.getRendaFixaById(id);
    if (dados == null) return null;
    return RendaFixaModel.fromJson(dados);
  }

  /// Insere um novo investimento
  Future<int> insert(RendaFixaModel investimento) async {
    return await _dbHelper.insertRendaFixa(investimento.toJson());
  }

  /// Atualiza um investimento
  Future<int> update(RendaFixaModel investimento) async {
    if (investimento.id == null) throw Exception('ID não pode ser nulo');
    return await _dbHelper.updateRendaFixa(investimento.toJson());
  }

  /// Deleta um investimento
  Future<int> delete(int id) async {
    return await _dbHelper.deleteRendaFixa(id);
  }

  /// Calcula estatísticas
  Future<Map<String, dynamic>> getEstatisticas() async {
    final investimentos = await getAll();

    double totalAplicado = 0;
    double totalAtual = 0;

    for (var inv in investimentos) {
      totalAplicado += inv.valorAplicado;
      totalAtual += inv.valorFinal ?? inv.valorAplicado;
    }

    return {
      'totalAplicado': totalAplicado,
      'totalAtual': totalAtual,
      'rendimentoTotal': totalAtual - totalAplicado,
      'quantidade': investimentos.length,
    };
  }

  /// 🔥 NOVO: Busca investimentos ativos
  Future<List<RendaFixaModel>> getAtivos() async {
    final todos = await getAll();
    final hoje = DateTime.now();
    return todos.where((inv) => inv.dataVencimento.isAfter(hoje)).toList();
  }

  /// 🔥 NOVO: Busca investimentos vencidos
  Future<List<RendaFixaModel>> getVencidos() async {
    final todos = await getAll();
    final hoje = DateTime.now();
    return todos.where((inv) => inv.dataVencimento.isBefore(hoje)).toList();
  }
}
