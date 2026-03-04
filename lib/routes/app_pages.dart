import 'package:flutter/material.dart';
import '../screens/dashboard.dart';
import '../screens/lancamentos.dart';
import '../screens/nova_transacao.dart';
import '../screens/investimentos_tabs.dart';
import '../screens/metas_screen.dart';
import 'app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.home: (context) => const DashboardScreen(),
    AppRoutes.dashboard: (context) => const DashboardScreen(),
    AppRoutes.lancamentos: (context) => const LancamentosScreen(),
    AppRoutes.novaTransacao: (context) => const NovaTransacaoScreen(),
    AppRoutes.investimentos: (context) => const InvestimentosTabsScreen(),
    AppRoutes.metas: (context) => const MetasScreen(),
  };
}
