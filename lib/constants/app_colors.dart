// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ========== CORES PRINCIPAIS ==========
  static const Color primary = Color(0xFF7B2CBF);
  static const Color primaryLight = Color(0xFFB084D9); // 🔥 FALTANDO!
  static const Color primaryDark = Color(0xFF5A1E8A);
  static const Color secondary = Color(0xFFB084D9);

  // ========== CORES DE FUNDO ==========
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color muted = Color(0xFFCED4DA);

  // ========== TEXTOS ==========
  static const Color textPrimary = Color(0xFF343A40);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD); // 🔥 FALTANDO!
  static const Color textDisabled = Color(0xFFCED4DA);

  // ========== BORDAS ==========
  static const Color border = Color(0xFFDEE2E6);
  static const Color borderDark = Color(0xFFCED4DA);
  static const Color divider = Color(0xFFE9ECEF);

  // ========== STATUS ==========
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF1B5E20);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningDark = Color(0xFFC56000);
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ========== BADGES ==========
  static const Color badgeBackground = Color(0xFF7B2CBF);
  static const Color badgeText = Colors.white;
  static const Color badgePago = Color(0xFF2E7D32);
  static const Color badgePendente = Color(0xFFFF8F00);
  static const Color badgeAtrasado = Color(0xFFC62828);

  // ========== CATEGORIAS ==========
  static const Map<String, Color> categoryColors = {
    'Alimentação': Color(0xFFFF7043),
    'Restaurante': Color(0xFFFF5722),
    'Mercado': Color(0xFFFF9800),
    'Transporte': Color(0xFF42A5F5),
    'Combustível': Color(0xFF2196F3),
    'Uber': Color(0xFF1976D2),
    'Moradia': Color(0xFF66BB6A),
    'Aluguel': Color(0xFF4CAF50),
    'Condomínio': Color(0xFF43A047),
    'Água': Color(0xFF00ACC1),
    'Luz': Color(0xFFFFD54F),
    'Saúde': Color(0xFFEF5350),
    'Farmácia': Color(0xFFE57373),
    'Educação': Color(0xFFAB47BC),
    'Investimentos': Color(0xFF7E57C2),
    'Lazer': Color(0xFFFFA726),
    'Outros': Color(0xFF9E9E9E),
    'Empréstimo': Color(0xFFF44336),
  };

  // ========== GRADIENTS ==========
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== MÉTODOS ==========
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['Outros']!;
  }
}
