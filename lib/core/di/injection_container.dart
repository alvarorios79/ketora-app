import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/gem/data/services/gemini_service.dart';
import '../../features/hoy/data/datasources/firestore_registro_datasource.dart';
import '../../features/hoy/data/repositories/registro_diario_repository_impl.dart';
import '../../features/hoy/domain/repositories/i_registro_diario_repository.dart';
import '../../features/hoy/domain/usecases/obtener_registro_diario.dart';
import '../../features/hoy/domain/usecases/guardar_alimento.dart';
import '../../features/hoy/domain/usecases/eliminar_alimento.dart';
import '../../features/hoy/domain/usecases/actualizar_agua.dart';
import '../../features/hoy/domain/usecases/gestionar_ayuno.dart';
import '../../features/hoy/presentation/bloc/hoy_bloc.dart';
import '../services/perfil_service.dart';

/// Service Locator global — el único lugar donde se construyen las dependencias.
///
/// Jerarquía de registro (de abajo hacia arriba):
///   Firestore (externo)
///     → Datasource
///       → Repository
///         → Use Cases
///           → BLoC
///             → UI
final sl = GetIt.instance;

Future<void> initDependencies() async {

  // ── Externos ────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  // ── Core Services ───────────────────────────────────────────
  sl.registerLazySingleton<PerfilService>(
    () => PerfilService(db: sl()),
  );

  // ── Feature: Hoy ────────────────────────────────────────────

  // Datasource
  sl.registerLazySingleton<FirestoreRegistroDatasource>(
    () => FirestoreRegistroDatasource(db: sl()),
  );

  // Repository
  sl.registerLazySingleton<IRegistroDiarioRepository>(
    () => RegistroDiarioRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => ObtenerRegistroDiario(sl()));
  sl.registerLazySingleton(() => GuardarAlimento(sl()));
  sl.registerLazySingleton(() => EliminarAlimento(sl()));
  sl.registerLazySingleton(() => ActualizarAgua(sl()));
  sl.registerLazySingleton(() => GestionarAyuno(sl()));

  // BLoC — factory para crear una nueva instancia por pantalla
  sl.registerFactory(() => HoyBloc(
    obtenerRegistro:  sl(),
    guardarAlimento:  sl(),
    eliminarAlimento: sl(),
    actualizarAgua:   sl(),
    gestionarAyuno:   sl(),
    perfilService:    sl(),
  ));

  // ── Feature: GEM ────────────────────────────────────────────
  sl.registerLazySingleton<GeminiService>(() => GeminiService());
}
