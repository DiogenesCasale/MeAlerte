import 'package:flutter/material.dart';

// --- CORES TEMA CLARO ---
const Color primaryColorLight = Color(0xFF007AFF); // Azul principal
const Color secondaryColorLight = Color(0xFFFF3B30); // Vermelho para alertas/deleção
const Color backgroundColorLight = Color(0xFFFFFFFF); // Fundo base branco
const Color scaffoldBackgroundColorLight = Color(0xFFF0F4F8); // Fundo de telas
const Color textColorLight = Color(0xFF333333); // Cor de texto principal
const Color surfaceColorLight = Color(0xFFFFFFFF); // Cor de superfícies (cards, etc)

// --- CORES TEMA ESCURO ---
const Color primaryColorDark = Color(0xFF0A84FF); // Azul mais claro para dark mode
const Color secondaryColorDark = Color(0xFFFF453A); // Vermelho mais claro
const Color backgroundColorDark = Color(0xFF1C1C1E); // Fundo base escuro
const Color scaffoldBackgroundColorDark = Color(0xFF000000); // Fundo de telas escuro
const Color textColorDark = Color(0xFFFFFFFF); // Texto branco
const Color surfaceColorDark = Color(0xFF2C2C2E); // Superfícies escuras

// --- CORES DOS TOASTS ---
const Color toastSuccessColor = Color(0xFF34C759); // Verde
const Color toastWarningColor = Color(0xFFFF9500); // Amarelo/Laranja
const Color toastErrorColor = Color(0xFFFF3B30); // Vermelho
const Color toastInfoColor = Color(0xFF007AFF); // Azul

// --- CORES DINÂMICAS (serão atualizadas conforme o tema) ---
Color primaryColor = primaryColorLight;
Color secondaryColor = secondaryColorLight;
Color backgroundColor = backgroundColorLight;
Color scaffoldBackgroundColor = scaffoldBackgroundColorLight;
Color textColor = textColorLight;
Color surfaceColor = surfaceColorLight;

// --- ESTILOS DE TEXTO DINÂMICOS ---
TextStyle get heading1Style => TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: textColor,
);

TextStyle get heading2Style => TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: textColor,
);

TextStyle get bodyTextStyle => TextStyle(
  fontSize: 16,
  color: textColor,
);

TextStyle get subtitleTextStyle => TextStyle(
  fontSize: 14,
  color: textColor.withValues(alpha: 0.6),
);

// --- FUNÇÃO PARA ATUALIZAR O TEMA ---
void updateTheme(bool isDarkMode) {
  if (isDarkMode) {
    primaryColor = primaryColorDark;
    secondaryColor = secondaryColorDark;
    backgroundColor = backgroundColorDark;
    scaffoldBackgroundColor = scaffoldBackgroundColorDark;
    textColor = textColorDark;
    surfaceColor = surfaceColorDark;
  } else {
    primaryColor = primaryColorLight;
    secondaryColor = secondaryColorLight;
    backgroundColor = backgroundColorLight;
    scaffoldBackgroundColor = scaffoldBackgroundColorLight;
    textColor = textColorLight;
    surfaceColor = surfaceColorLight;
  }
}
