import 'package:flutter/material.dart';

class AppColors {
  // Cores principais
  static const Color primaryPurple = Color(0xFF6A1B9A);
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color accentPurple = Color(0xFFBA68C8);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8E24AA), Color(0xFFAB47BC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFC62828), Color(0xFFEF5350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cores de feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);

  // Tons para variações
  static const Color profitGreen = Color(0xFF2E7D32);
  static const Color lossRed = Color(0xFFC62828);

  // Fundos
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E2F);

  // Textos
  static const Color textPrimary = Color(0xFF1E1E2F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Cores para categorias
  static const Map<String, Color> categoryColors = {
    'Alimentação': Color(0xFFFF9800),
    'Lazer': Color(0xFF9C27B0),
    'Transporte': Color(0xFF2196F3),
    'Saúde': Color(0xFFF44336),
    'Educação': Color(0xFF009688),
    'Moradia': Color(0xFF795548),
    'Cartão de Crédito': Color(0xFFE91E63),
    'Empréstimo': Color(0xFFFF5722),
    'Cuidados Pessoais': Color(0xFFE91E63),
    'Investimentos': Color(0xFF3F51B5),
    'Outros': Color(0xFF9E9E9E),
    'Renda Extra': Color(0xFF4CAF50),
    'Salário': Color(0xFF8BC34A),
  };
}
