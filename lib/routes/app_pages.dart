// lib/constants/app_pages.dart

import 'package:flutter/material.dart';
import '../screens/dashboard.dart';
import '../screens/lancamentos.dart';
import '../screens/nova_transacao.dart';
import '../screens/investimentos_tabs.dart';
import '../screens/metas_screen.dart';
import '../screens/contas_fixas_screen.dart'; // 🔥 IMPORT ADICIONADO
import '../screens/backup_screen.dart'; // 🔥 IMPORT ADICIONADO
import '../screens/notificacoes_screen.dart'; // 🔥 IMPORT ADICIONADO
import 'app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.home: (context) => const DashboardScreen(),
    AppRoutes.dashboard: (context) => const DashboardScreen(),
    AppRoutes.lancamentos: (context) => const LancamentosScreen(),
    AppRoutes.novaTransacao: (context) => const NovaTransacaoScreen(),
    AppRoutes.investimentos: (context) => const InvestimentosTabsScreen(),
    AppRoutes.metas: (context) => const MetasScreen(),
    // 🔥 Rotas adicionais (opcionais)
    AppRoutes.contasFixas: (context) => const ContasFixasScreen(),
    AppRoutes.backup: (context) => const BackupScreen(),
    AppRoutes.notificacoes: (context) => const NotificacoesScreen(),
  };

  // 🔥 Método para navegação com parâmetros (se precisar)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.novaTransacao:
        return MaterialPageRoute(
          builder: (_) => const NovaTransacaoScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
    }
  }
}
