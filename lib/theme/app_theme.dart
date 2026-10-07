import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores del panel web, para que la app combine.
class AppColors {
  static const naranja = Color(0xFFEA580C);
  static const naranjaOscuro = Color(0xFFC2410C);
  static const naranjaClaro = Color(0xFFFFEDD5);
  static const azul = Color(0xFF2563EB);
  static const azulClaro = Color(0xFFDBEAFE);
  static const texto = Color(0xFF1E1E1E);
  static const textoSecundario = Color(0xFF71717A);
  static const fondo = Color(0xFFF4F4F5);
  static const blanco = Color(0xFFFFFFFF);
  static const rojo = Color(0xFFDC2626);
  static const verde = Color(0xFF16A34A); // para "Acceso permitido"
}

class AppTheme {
  static ThemeData get claro {
    // Inter para todo el texto normal; Poppins solo en títulos.
    final inter = GoogleFonts.inter().fontFamily;
    final poppins = GoogleFonts.poppins().fontFamily;

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: inter,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.naranja,
        primary: AppColors.naranja,
        secondary: AppColors.azul,
        error: AppColors.rojo,
      ),
      scaffoldBackgroundColor: AppColors.fondo,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: poppins, fontWeight: FontWeight.w700, color: AppColors.texto),
        titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: poppins, fontWeight: FontWeight.w600, color: AppColors.texto),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.blanco,
        foregroundColor: AppColors.texto,
        titleTextStyle: TextStyle(
            fontFamily: poppins, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.texto),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.naranja, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.naranja,
          foregroundColor: AppColors.blanco,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontFamily: poppins, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

