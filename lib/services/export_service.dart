import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class ExportService {
  final DBHelper db = DBHelper();

  Future<String?> _getExportPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/exports';
    final dir = Directory(path);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return '$path/$fileName';
  }

  Future<void> exportLancamentosToCsv() async {
    try {
      final lancamentos = await db.getAllLancamentos();

      List<List<String>> rows = [
        ['ID', 'Descrição', 'Tipo', 'Categoria', 'Valor', 'Data', 'Observação']
      ];

      for (var item in lancamentos) {
        rows.add([
          item['id'].toString(),
          item['descricao'] ?? '',
          item['tipo'] ?? '',
          item['categoria'] ?? '',
          (item['valor'] ?? 0).toStringAsFixed(2).replaceAll('.', ','),
          item['data'] ?? '',
          item['observacao'] ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final fileName =
          'lancamentos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = await _getExportPath(fileName);

      if (path != null) {
        File file = File(path);
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(path)],
            text: 'Exportação de Lançamentos');
      }
    } catch (e) {
      throw Exception('Erro ao exportar: $e');
    }
  }

  Future<void> exportInvestimentosToCsv() async {
    try {
      final investimentos = await db.getAllInvestimentos();

      List<List<String>> rows = [
        [
          'ID',
          'Ticker',
          'Tipo',
          'Quantidade',
          'Preço Médio',
          'Preço Atual',
          'Data Compra'
        ]
      ];

      for (var item in investimentos) {
        rows.add([
          item['id'].toString(),
          item['ticker'] ?? '',
          item['tipo'] ?? '',
          (item['quantidade'] ?? 0).toStringAsFixed(2).replaceAll('.', ','),
          (item['preco_medio'] ?? 0).toStringAsFixed(2).replaceAll('.', ','),
          (item['preco_atual'] ?? 0).toStringAsFixed(2).replaceAll('.', ','),
          item['data_compra'] ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final fileName =
          'investimentos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = await _getExportPath(fileName);

      if (path != null) {
        File file = File(path);
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(path)],
            text: 'Exportação de Investimentos');
      }
    } catch (e) {
      throw Exception('Erro ao exportar: $e');
    }
  }
}
