import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/app_shell.dart';
import '../../features/hoy/presentation/pages/hoy_page.dart';
import '../../features/registro/presentation/pages/registro_page.dart';
import '../../features/progreso/presentation/pages/progreso_page.dart';
import '../../features/gem/presentation/pages/gem_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/ejercicio/presentation/pages/ejercicio_page.dart';
import '../../features/glucosa/presentation/pages/glucosa_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/gem/presentation/pages/gem_quick_page.dart';
import '../../features/registro/presentation/pages/scanner_page.dart';

// Claves de ruta
class AppRoutes {
  static const String splash      = '/';
  static const String onboarding  = '/onboarding';
  static const String login       = '/login';
  static const String shell       = '/app';
  static const String hoy         = '/app/hoy';
  static const String registro    = '/app/registro';
  static const String progreso    = '/app/progreso';
  static const String gem         = '/app/gem';

  // Sub-rutas Hoy
  static const String addAlimento = '/app/add-alimento';
  static const String scanner     = '/app/scanner';

  // Sub-rutas GEM
  static const String gemChat     = '/app/gem/chat';
  static const String gemRecetas  = '/app/gem/recetas';
  static const String gemSuper    = '/app/gem/supermercado';

  // Sub-rutas Progreso
  static const String mediciones  = '/app/progreso/mediciones';
  static const String reportePDF  = '/app/progreso/reporte';

  // Ejercicio
  static const String ejercicio   = '/app/ejercicio';

  // Glucosa
  static const String glucosa     = '/app/glucosa';

  // Perfil
  static const String perfil      = '/app/perfil';
}

final _rootNavigatorKey   = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey  = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Listenable que escucha cambios de auth state para que GoRouter redirija
final _authListenable = _AuthStateListenable();

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.onboarding,
  refreshListenable: _authListenable,
  debugLogDiagnostics: true,

  // ── Redirect basado en estado de autenticación ────────────
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final location = state.uri.toString();

    final isPublic = location == AppRoutes.onboarding || location == AppRoutes.login;
    final isApp    = location.startsWith('/app');

    // Si intenta acceder a /app sin estar logueado → login
    if (isApp && !isLoggedIn) return AppRoutes.login;

    // Si está logueado y va a login u onboarding → hoy directamente
    if (isLoggedIn && (location == AppRoutes.login || location == AppRoutes.onboarding)) {
      return AppRoutes.hoy;
    }

    return null; // Sin redirección
  },

  routes: [
    // ── Onboarding ────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),

    // ── Auth ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    // ── Shell con 5 tabs ──────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.hoy,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HoyPage()),
        ),
        GoRoute(
          path: AppRoutes.registro,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RegistroPage()),
        ),
        GoRoute(
          path: AppRoutes.progreso,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProgresoPage()),
        ),
        GoRoute(
          path: AppRoutes.gem,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GemPage()),
        ),
        GoRoute(
          path: AppRoutes.ejercicio,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EjercicioPage()),
        ),
      ],
    ),

    // ── Rutas fuera del shell (pantalla completa) ────────────
    GoRoute(
      path: AppRoutes.perfil,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PerfilPage(),
    ),
    GoRoute(
      path: AppRoutes.glucosa,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GlucosaPage(),
    ),

    // ── GEM Quick Actions ─────────────────────────────────────
    // ── Scanner de código de barras ───────────────────────────
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) {
        final tipoComida = state.uri.queryParameters['tipo'] ?? 'General';
        return ScannerPage(tipoComida: tipoComida);
      },
    ),

    GoRoute(
      path: AppRoutes.gemRecetas,
      builder: (context, state) => const GemQuickPage(
        titulo: 'Recetas Keto',
        emoji: '🍳',
        mensajeInicial: 'Dame una receta keto fácil para hoy con ingredientes accesibles en Latinoamérica',
        sugerencias: [
          'Desayuno rápido sin huevos',
          'Cena keto en 20 minutos',
          'Snack para media tarde',
          'Postre sin azúcar',
        ],
      ),
    ),

    GoRoute(
      path: AppRoutes.gemSuper,
      builder: (context, state) => const GemQuickPage(
        titulo: 'Lista del Súper',
        emoji: '🛒',
        mensajeInicial: 'Arma mi lista del supermercado keto para la semana con precios accesibles en Latinoamérica',
        sugerencias: [
          'Solo proteínas y grasas',
          'Presupuesto bajo',
          'Lista para 2 personas',
          'Snacks keto para llevar',
        ],
      ),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Ruta no encontrada: ${state.error}'),
    ),
  ),
);
