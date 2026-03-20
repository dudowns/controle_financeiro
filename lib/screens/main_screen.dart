// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/theme_service.dart';
import '../widgets/theme_selector.dart';
import '../widgets/backup_modal.dart';
import '../widgets/notificacoes_modal.dart'; // 🔥 NOVO!
import 'dashboard.dart';
import 'lancamentos.dart';
import 'contas_do_mes_screen.dart';
import 'investimentos_tabs.dart';
import 'metas_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  final List<String> _titles = [
    'Dashboard',
    'Gastos',
    'Contas do Mês',
    'Invest',
    'Metas',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _screens = const [
      DashboardScreen(),
      LancamentosScreen(),
      ContasDoMesScreen(),
      InvestimentosTabsScreen(),
      MetasScreen(),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        // 🎨 BOTÕES NO AppBar - TODOS MODAIS!
        actions: [
          // 🟢 SELETOR DE TEMA (POPUP)
          const ThemeSelector(),

          // 🟢 BOTÃO DE BACKUP (MODAL)
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.backup_outlined),
              onPressed: () {
                BackupModal.show(
                  context: context,
                  onBackupRealizado: () {
                    debugPrint('Backup realizado/restaurado/excluído');
                  },
                );
              },
              tooltip: 'Backup',
              color: Colors.white,
            ),
          ),

          // 🟢 BOTÃO DE NOTIFICAÇÕES (MODAL)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                NotificacoesModal.show(context: context);
              },
              tooltip: 'Notificações',
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                    Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(
                    Icons.pie_chart_outline, Icons.pie_chart, 'Gastos', 1),
                _buildNavItem(
                    Icons.receipt_outlined, Icons.receipt, 'Contas', 2),
                _buildNavItem(
                    Icons.trending_up_outlined, Icons.trending_up, 'Invest', 3),
                _buildNavItem(Icons.flag_outlined, Icons.flag, 'Metas', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData iconOutlined, IconData iconFilled, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          _animationController.forward(from: 0);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isSelected ? 8 : 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ScaleTransition(
              scale: isSelected
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Icon(
                isSelected ? iconFilled : iconOutlined,
                color:
                    isSelected ? AppColors.primary : AppColors.muted(context),
                size: isSelected ? 26 : 22,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : AppColors.muted(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
