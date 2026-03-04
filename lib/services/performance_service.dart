import 'package:flutter/foundation.dart';

class PerformanceService {
  static final Stopwatch _stopwatch = Stopwatch();
  static final Map<String, int> _tempos = {};

  static void start(String operacao) {
    _stopwatch.start();
  }

  static void stop(String operacao) {
    _stopwatch.stop();
    _tempos[operacao] = _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();

    if (kDebugMode) {
      debugPrint('⏱️ $operacao: ${_tempos[operacao]}ms');
    }
  }

  static Map<String, int> getRelatorio() {
    return Map.from(_tempos);
  }

  static void limpar() {
    _tempos.clear();
  }
}
