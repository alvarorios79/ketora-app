import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'core/di/injection_container.dart' as di show initDependencies, sl;
import 'core/services/notification_service.dart';
import 'core/services/perfil_service.dart';
import 'features/gem/data/services/gemini_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación fija: portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Cargar variables de entorno (.env)
  await dotenv.load(fileName: '.env');

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notificaciones locales
  await NotificationService.instance.init();
  await NotificationService.instance.programarMotivacionDiaria();

  // Inyección de dependencias
  await di.initDependencies();

  // Cargar perfil del usuario logueado y sincronizar con GEM
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    final perfil = await di.sl<PerfilService>().cargarPerfil(uid);
    if (perfil != null) {
      di.sl<GeminiService>().actualizarPerfil(
        nombre:    perfil.nombre,
        objetivo:  perfil.objetivo,
        kcal:      perfil.kcal,
        grasasG:   perfil.grasasG,
        proteinaG: perfil.proteinaG,
        carbosG:   perfil.carbosG,
        nivel:     _mapearNivel(perfil.experiencia),
      );
    }
  }

  runApp(const KetoraApp());
}

String _mapearNivel(String experiencia) {
  switch (experiencia) {
    case 'Tengo experiencia': return 'intermedio';
    case 'Lo intenté':        return 'retomador';
    default:                  return 'principiante';
  }
}

class KetoraApp extends StatelessWidget {
  const KetoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KETORA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
