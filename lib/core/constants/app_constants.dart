/// Constantes globales de KETORA
class AppConstants {
  AppConstants._();

  // ── App Info ─────────────────────────────────────────────────
  static const String appName      = 'KETORA';
  static const String appVersion   = '1.0.0';
  static const String appTagline   = 'Tu guía keto inteligente';

  // ── GEM (IA Coach) ────────────────────────────────────────────
  static const String gemName      = 'GEM';
  static const String gemModel     = 'gemini-1.5-flash';
  static const int    gemMaxTokens = 2048;

  // ── Macros por defecto (dieta keto estándar) ─────────────────
  static const double macroGrasasPct   = 0.70;  // 70%
  static const double macroProteinaPct = 0.25;  // 25%
  static const double macroCarbsPct    = 0.05;  // 5% carbohidratos netos

  // ── Keto Traffic Light (g/100g) ────────────────────────────
  static const double ketoClaseA = 5.0;   // <= 5g — SÍ keto
  static const double ketoClaseB = 15.0;  // 5-15g — moderado
  static const double ketoClaseC = 25.0;  // 15-25g — con cuidado
  // > 25g = Clase F — evitar

  // ── Metas electrolitos diarias ────────────────────────────
  static const int metaSodioMg    = 2500;  // mg
  static const int metaMagnesioMg = 400;   // mg
  static const int metaPotasioMg  = 3500;  // mg

  // ── Agua ─────────────────────────────────────────────────────
  static const int metaAguaMl     = 2500;  // ml por defecto

  // ── Ayuno intermitente por defecto ────────────────────────
  static const int ayunoVentanaHoras = 8;  // ventana de alimentación
  static const int ayunoHoras        = 16; // horas de ayuno (16:8)

  // ── RevenueCat ─────────────────────────────────────────────
  static const String rcMensual  = 'ketora_premium_mensual';
  static const String rcAnual    = 'ketora_premium_anual';

  // ── Precios MXN ────────────────────────────────────────────
  static const double precioMensualMXN = 149.0;
  static const double precioAnualMXN   = 999.0;

  // ── Firebase Collections ────────────────────────────────────
  static const String colUsuarios    = 'usuarios';
  static const String colGemChats    = 'gem_chats';
  static const String colRegistros   = 'registros_diarios';
  static const String colProgreso    = 'progreso';
  static const String colMediciones  = 'mediciones';

  // ── Shared Preferences Keys ────────────────────────────────
  static const String prefOnboardingCompleto = 'onboarding_completo';
  static const String prefTemaOscuro         = 'tema_oscuro';
  static const String prefUid                = 'uid';

  // ── Gamificación – Niveles ─────────────────────────────────
  static const List<String> nivelesKeto = [
    'Principiante Keto',    // 0-7 días
    'Adaptándome',          // 8-30 días
    'En Cetosis',           // 31-90 días
    'Keto Experto',         // 91-180 días
    'Maestro Keto',         // 181+ días
  ];
}
