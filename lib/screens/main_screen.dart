// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'lancamentos.dart';
import 'investimentos_tabs.dart';
import 'metas_screen.dart';
import 'contas_fixas_screen.dart'; // 🔥 NOVA IMPORTAÇÃO!
import 'backup_screen.dart';
import 'notificacoes_screen.dart';
import '../constants/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de telas na ordem do menu inferior
  final List<Widget> _screens = [
    const DashboardScreen(), // Índice 0
    LancamentosScreen(), // Índice 1
    const ContasFixasScreen(), // Índice 2 - NOVA ABA!
    const InvestimentosTabsScreen(), // Índice 3
    const MetasScreen(), // Índice 4
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
            icon: const Icon(Icons.backup),
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
            icon: const Icon(Icons.notifications),
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
        type: BottomNavigationBarType.fixed, // Necessário para 5 itens
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Gastos'),
          // 🔥 NOVO ITEM - Contas Fixas
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Contas Fixas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Invest'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
        ],
        // Cores do menu inferior
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
