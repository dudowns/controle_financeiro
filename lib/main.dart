import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // 🔥 NOVO IMPORT!

import 'screens/splash_screen.dart';
import 'constants/app_themes.dart';
import 'services/notification_service.dart';
import 'services/logger_service.dart';
import 'services/theme_service.dart'; // 🔥 NOVO IMPORT!
import 'screens/main_screen.dart'; // 🔥 PARA O MaterialApp
import 'screens/theme_settings_screen.dart'; // 🔥 PARA AS ROTAS

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

  // 🔥 INICIALIZA O ThemeService ANTES de rodar o app
  final themeService = ThemeService();
  await themeService.loadTheme(); // ← ✅ CORRIGIDO! (sem _)

  runApp(
    // 🔥 PROVIDER ENVOLVENDO TODO O APP!
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 CONSUMER para acessar o ThemeService
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Controle Financeiro',
          debugShowCheckedModeBanner: false,
          theme: themeService.lightTheme, // 🔥 Usa o tema do service
          darkTheme: themeService.darkTheme, // 🔥 Tema escuro
          themeMode: themeService.themeMode, // 🔥 Modo (claro/escuro/sistema)
          home: const SplashScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          // 🔥 ROTAS para navegação
          routes: {
            '/main': (context) => const MainScreen(),
            '/theme-settings': (context) => const ThemeSettingsScreen(),
          },
        );
      },
    );
  }
}
