// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard.dart'; // 🔥 ADICIONADO screens/
import 'screens/lancamentos.dart'; // 🔥 ADICIONADO screens/
import 'screens/investimentos_tabs.dart'; // 🔥 ADICIONADO screens/
import 'screens/metas_screen.dart'; // 🔥 ADICIONADO screens/
import 'screens/backup_screen.dart'; // 🔥 ADICIONADO screens/
import 'screens/notificacoes_screen.dart'; // 🔥 ADICIONADO screens/
import 'constants/app_themes.dart';
import 'services/notification_service.dart';
import 'services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('pt_BR', null);

    final notificationService = NotificationService();
    await notificationService.init();

    LoggerService.success('App inicializado com sucesso!');
  } catch (e) {
    LoggerService.error('Erro na inicialização', e);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: AppThemes.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
    );
  }
}
