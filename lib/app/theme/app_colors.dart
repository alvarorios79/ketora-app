import 'package:flutter/material.dart';

/// Paleta de colores KETORA — basada en logos oficiales
/// Negro profundo + Verde bosque + Lima brillante + Oro metálico
class AppColors {
  AppColors._();

  // ── Brand primarios (del logo) ──────────────────────────────
  static const Color negro      = Color(0xFF090E09); // Fondo principal — negro con tinte verde
  static const Color verdeOs    = Color(0xFF0D3B1E); // Verde bosque profundo (logo background)
  static const Color verde      = Color(0xFF16A34A); // Verde medio — botones, íconos
  static const Color verdeMedio = Color(0xFF7CB518); // Lima brillante del logo (K en KETORA)
  static const Color verdeClaro = Color(0xFFDCFCE7); // Verde muy suave para chips light
  static const Color oro        = Color(0xFFC9A227); // Oro metálico del anillo (logo)
  static const Color oroClaro   = Color(0xFFF5E7A0); // Oro claro para textos secundarios dorados
  static const Color blanco     = Color(0xFFFFFFFF);

  // ── Fondos ─────────────────────────────────────────────────
  static const Color surface      = Color(0xFF0D1510); // Scaffold principal — negro verdoso
  static const Color cardBg       = Color(0xFF182318); // Cards sobre el fondo oscuro
  static const Color cardBgLight  = Color(0xFFFFFFFF); // Cards con contenido claro (formularios)
  static const Color fondoVerde   = Color(0xFF0F2B18); // Verde muy oscuro para secciones
  static const Color fondoOro     = Color(0xFF1E1A0A); // Fondo dorado oscuro
  static const Color fondoRojo    = Color(0xFF2B0F0F); // Fondo error oscuro
  static const Color fondoAzul    = Color(0xFF0F1B2B); // Fondo info oscuro
  static const Color fondoGris    = Color(0xFF1E2B1E); // Input background oscuro
  static const Color fondoNaranja = Color(0xFF2B1A0A); // Naranja oscuro

  // ── Semánticos ────────────────────────────────────────────
  static const Color success  = Color(0xFF7CB518); // Lima brillante (del logo)
  static const Color warning  = Color(0xFFC9A227); // Oro metálico (del logo)
  static const Color error    = Color(0xFFEF4444); // Rojo
  static const Color info     = Color(0xFF3B82F6); // Azul

  // ── Macros ────────────────────────────────────────────────
  static const Color macroGrasas   = Color(0xFFC9A227); // Oro — grasas
  static const Color macroProtein  = Color(0xFF3B82F6); // Azul — proteína
  static const Color macroCarbos   = Color(0xFF7CB518); // Lima — carbos
  static const Color macroCalorias = Color(0xFFA855F7); // Púrpura — calorías

  // ── Keto Traffic Light ────────────────────────────────────
  static const Color ketoA = Color(0xFF7CB518); // keto friendly
  static const Color ketoB = Color(0xFFC9A227); // moderado
  static const Color ketoC = Color(0xFFF97316); // cuidado
  static const Color ketoF = Color(0xFFEF4444); // evitar

  // ── Superficies ──────────────────────────────────────────
  static const Color cardBgDark   = Color(0xFF182318);
  static const Color divider      = Color(0xFF2A3D2A); // Divisor oscuro sutil
  static const Color surfaceDark  = Color(0xFF090E09);

  // ── Texto ─────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFECF5EC); // Blanco verdoso — texto principal
  static const Color textSecondary = Color(0xFF8FAF8F); // Verde grisáceo — texto secundario
  static const Color textHint      = Color(0xFF4A6B4A); // Verde oscuro — placeholder
  static const Color textInverse   = Color(0xFF090E09); // Negro — sobre fondos claros
}
