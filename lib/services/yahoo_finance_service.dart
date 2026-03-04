// lib/services/yahoo_finance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/performance_service.dart';

// 🔥 CLASSE DE CACHE FORA DO SERVIÇO
class CachePrice {
  final double price;
  final DateTime timestamp;

  CachePrice(this.price, this.timestamp);

  // 🔥 AGORA USA _cacheDuration (warning resolvido!)
  bool get isValid =>
      DateTime.now().difference(timestamp) < YahooFinanceService.cacheDuration;
}

class YahooFinanceService {
  static final YahooFinanceService _instance = YahooFinanceService._internal();
  factory YahooFinanceService() => _instance;
  YahooFinanceService._internal();

  // 🔥 CACHE DE PREÇOS
  static final Map<String, CachePrice> _priceCache = {};

  // 🔥 TORNAR PÚBLICO PARA ACESSO NA CLASSE CachePrice
  static const Duration cacheDuration = Duration(minutes: 5); // sem underline
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 10);

  // 🔥 MÉTODO PRINCIPAL COM CACHE E RETRY
  Future<double?> getPrecoAtual(String ticker) async {
    PerformanceService.start('yahoo_getPreco_$ticker');

    // Verificar cache - USA cacheDuration indiretamente via CachePrice.isValid
    if (_priceCache.containsKey(ticker) && _priceCache[ticker]!.isValid) {
      PerformanceService.stop('yahoo_getPreco_$ticker (cache)');
      return _priceCache[ticker]!.price;
    }

    // ... resto do código igual
    for (int tentativa = 1; tentativa <= _maxRetries; tentativa++) {
      try {
        final url = Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/$ticker.SA');

        final response = await http.get(url).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['chart']['result'] != null &&
              data['chart']['result'].isNotEmpty) {
            final result = data['chart']['result'][0];
            final meta = result['meta'];
            final preco = meta['regularMarketPrice']?.toDouble();

            if (preco != null && preco > 0) {
              // Salvar no cache
              _priceCache[ticker] = CachePrice(preco, DateTime.now());

              PerformanceService.stop('yahoo_getPreco_$ticker');
              return preco;
            }
          }
        }

        if (tentativa < _maxRetries) {
          await Future.delayed(Duration(seconds: tentativa * 2));
        }
      } catch (e) {
        debugPrint('⚠️ Tentativa $tentativa falhou para $ticker: $e');
        if (tentativa == _maxRetries) {
          debugPrint('❌ Todas as tentativas falharam para $ticker');
        } else {
          await Future.delayed(Duration(seconds: tentativa));
        }
      }
    }

    PerformanceService.stop('yahoo_getPreco_$ticker (falha)');
    return null;
  }

  // 🔥 MÉTODO PARA LIMPAR CACHE
  void limparCache() {
    _priceCache.clear();
  }

  // 🔥 MÉTODO PARA REMOVER CACHE DE UM TICKER ESPECÍFICO
  void removerDoCache(String ticker) {
    _priceCache.remove(ticker);
  }

  // 🔥 MÉTODO PARA BUSCAR DADOS COMPLETOS
  Future<Map<String, dynamic>?> getDadosCompletos(String ticker) async {
    PerformanceService.start('yahoo_getCompleto_$ticker');

    try {
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$ticker.SA');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['chart']['result'] != null &&
            data['chart']['result'].isNotEmpty) {
          final result = data['chart']['result'][0];
          final meta = result['meta'];
          final indicators = result['indicators'];
          final quote = indicators['quote'][0];

          final precoAtual = meta['regularMarketPrice']?.toDouble();
          final precoAbertura = quote['open']?.last?.toDouble();
          final maximaDia = quote['high']?.last?.toDouble();
          final minimaDia = quote['low']?.last?.toDouble();
          final volume = quote['volume']?.last?.toInt();

          double? variacao;
          if (precoAbertura != null && precoAtual != null) {
            variacao = ((precoAtual - precoAbertura) / precoAbertura) * 100;
          }

          final dados = {
            'nome': meta['longName'] ?? meta['symbol'],
            'precoAtual': precoAtual,
            'precoAbertura': precoAbertura,
            'maximaDia': maximaDia,
            'minimaDia': minimaDia,
            'volume': volume,
            'variacao': variacao,
            'variacaoPercentual': variacao,
          };

          PerformanceService.stop('yahoo_getCompleto_$ticker');
          return dados;
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados completos de $ticker: $e');
    }

    PerformanceService.stop('yahoo_getCompleto_$ticker (falha)');
    return null;
  }

  // 🔥 MÉTODO PARA BUSCAR DADOS HISTÓRICOS
  Future<List<Map<String, dynamic>>> getDadosHistoricos(
    String ticker, {
    int dias = 30,
  }) async {
    PerformanceService.start('yahoo_getHistorico_$ticker');

    try {
      final agora = DateTime.now();
      final periodo = agora.subtract(Duration(days: dias));

      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$ticker.SA?'
          'period1=${periodo.millisecondsSinceEpoch ~/ 1000}&'
          'period2=${agora.millisecondsSinceEpoch ~/ 1000}&'
          'interval=1d');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['chart']['result'] != null &&
            data['chart']['result'].isNotEmpty) {
          final result = data['chart']['result'][0];
          final timestamps = result['timestamp'] as List;
          final indicators = result['indicators'];
          final quote = indicators['quote'][0];

          final List<Map<String, dynamic>> historico = [];

          for (int i = 0; i < timestamps.length; i++) {
            final data =
                DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000);
            final preco = quote['close']?[i]?.toDouble();
            final abertura = quote['open']?[i]?.toDouble();
            final maxima = quote['high']?[i]?.toDouble();
            final minima = quote['low']?[i]?.toDouble();
            final volume = quote['volume']?[i]?.toInt();

            if (preco != null && preco > 0) {
              historico.add({
                'data': data,
                'preco': preco,
                'abertura': abertura,
                'maxima': maxima,
                'minima': minima,
                'volume': volume,
              });
            }
          }

          PerformanceService.stop('yahoo_getHistorico_$ticker');
          return historico;
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar dados históricos de $ticker: $e');
    }

    PerformanceService.stop('yahoo_getHistorico_$ticker (falha)');
    return [];
  }

  // 🔥 MÉTODO PARA MÚLTIPLOS TICKERS DE UMA VEZ
  Future<Map<String, double?>> getPrecosEmLote(List<String> tickers) async {
    PerformanceService.start('yahoo_getLote');

    final Map<String, double?> resultados = {};

    // Primeiro, verificar cache
    final tickersParaBuscar = <String>[];

    for (var ticker in tickers) {
      if (_priceCache.containsKey(ticker) && _priceCache[ticker]!.isValid) {
        resultados[ticker] = _priceCache[ticker]!.price;
      } else {
        tickersParaBuscar.add(ticker);
      }
    }

    // Buscar os que não estão no cache
    for (var ticker in tickersParaBuscar) {
      final preco = await getPrecoAtual(ticker);
      resultados[ticker] = preco;
    }

    PerformanceService.stop('yahoo_getLote');
    return resultados;
  }
}
