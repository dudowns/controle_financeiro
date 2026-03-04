// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'lancamentos.dart';
import 'investimentos_tabs.dart';
import 'metas_screen.dart';
import 'backup_screen.dart'; // 🔥 IMPORT DA TELA DE BACKUP
import 'notificacoes_screen.dart'; // 🔥 IMPORT DA TELA DE NOTIFICAÇÕES
import '../constants/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    LancamentosScreen(),
    const InvestimentosTabsScreen(),
    const MetasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        // 🔥 BOTÕES NO CANTO SUPERIOR DIREITO
        actions: [
          // Botão de Backup
          IconButton(
            icon: const Icon(Icons.backup), // 🔥 ÍCONE DE BACKUP
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
            tooltip: 'Backup e Restauração',
          ),
          // Botão de Notificações
          IconButton(
            icon: const Icon(Icons.notifications), // 🔥 ÍCONE DE NOTIFICAÇÃO
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacoesScreen(),
                ),
              );
            },
            tooltip: 'Notificações',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Gastos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Invest'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
        ],
      ),
    );
  }
}
