import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/alimento_registrado_entity.dart';
import '../../domain/entities/objetivos_diarios_entity.dart';
import '../../domain/entities/registro_diario_entity.dart';
import '../../domain/usecases/obtener_registro_diario.dart';
import '../../domain/usecases/guardar_alimento.dart';
import '../../domain/usecases/eliminar_alimento.dart';
import '../../domain/usecases/actualizar_agua.dart';
import '../../domain/usecases/gestionar_ayuno.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/perfil_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class HoyEvent extends Equatable {
  const HoyEvent();
  @override
  List<Object?> get props => [];
}

/// Se dispara al abrir la pantalla Hoy. Inicia el Stream de Firestore.
class HoyIniciarEscucha extends HoyEvent {
  final String uid;
  final DateTime fecha;
  const HoyIniciarEscucha({required this.uid, required this.fecha});
  @override
  List<Object?> get props => [uid, fecha];
}

/// Llega cuando Firestore envía nuevos datos (tiempo real)
class HoyRegistroActualizado extends HoyEvent {
  final RegistroDiarioEntity registro;
  const HoyRegistroActualizado(this.registro);
  @override
  List<Object?> get props => [registro];
}

/// El usuario toca "+ Vaso" en agua
class HoyAgregarAgua extends HoyEvent {
  final int mililitros;
  const HoyAgregarAgua({this.mililitros = 250});
  @override
  List<Object?> get props => [mililitros];
}

/// El usuario confirma un alimento desde el modal del +
class HoyGuardarAlimento extends HoyEvent {
  final AlimentoRegistradoEntity alimento;
  const HoyGuardarAlimento(this.alimento);
  @override
  List<Object?> get props => [alimento];
}

/// El usuario elimina un alimento de su registro
class HoyEliminarAlimento extends HoyEvent {
  final String alimentoId;
  const HoyEliminarAlimento(this.alimentoId);
  @override
  List<Object?> get props => [alimentoId];
}

class HoyIniciarAyuno extends HoyEvent {}
class HoyRomperAyuno extends HoyEvent {}

/// Error recibido del Stream de Firestore
class HoyErrorRecibido extends HoyEvent {
  final String mensaje;
  const HoyErrorRecibido(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class HoyState extends Equatable {
  const HoyState();
  @override
  List<Object?> get props => [];
}

class HoyCargando extends HoyState {}

class HoyCargado extends HoyState {
  final RegistroDiarioEntity registro;
  final ObjetivosDiariosEntity objetivos;

  const HoyCargado({
    required this.registro,
    required this.objetivos,
  });

  // Helpers para la UI
  double get caloriasConsumidas => registro.caloriasTotal;
  double get caloriasRestantes  => objetivos.caloriasObjetivo - caloriasTotal;
  double get caloriasTotal      => registro.caloriasTotal;
  double get pctGrasas          => _pct(registro.grasasTotal, objetivos.grasasObjetivoG);
  double get pctProteina        => _pct(registro.proteinaTotal, objetivos.proteinaObjetivoG);
  double get pctCarbos          => _pct(registro.carbosTotal, objetivos.carbosObjetivoG);
  double get pctAgua            => _pct(registro.aguaMl.toDouble(), objetivos.aguaObjetivoMl.toDouble());

  double _pct(double consumido, double objetivo) =>
      objetivo > 0 ? (consumido / objetivo).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [registro, objetivos];
}

class HoyError extends HoyState {
  final String mensaje;
  const HoyError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class HoyBloc extends Bloc<HoyEvent, HoyState> {
  final ObtenerRegistroDiario _obtenerRegistro;
  final GuardarAlimento       _guardarAlimento;
  final EliminarAlimento      _eliminarAlimento;
  final ActualizarAgua        _actualizarAgua;
  final GestionarAyuno        _gestionarAyuno;
  final PerfilService         _perfilService;

  StreamSubscription<RegistroDiarioEntity>? _registroSub;

  // Estado interno del UID y fecha activos
  String?   _uid;
  DateTime? _fecha;

  HoyBloc({
    required ObtenerRegistroDiario obtenerRegistro,
    required GuardarAlimento guardarAlimento,
    required EliminarAlimento eliminarAlimento,
    required ActualizarAgua actualizarAgua,
    required GestionarAyuno gestionarAyuno,
    required PerfilService perfilService,
  })  : _obtenerRegistro  = obtenerRegistro,
        _guardarAlimento   = guardarAlimento,
        _eliminarAlimento  = eliminarAlimento,
        _actualizarAgua    = actualizarAgua,
        _gestionarAyuno    = gestionarAyuno,
        _perfilService     = perfilService,
        super(HoyCargando()) {
    on<HoyIniciarEscucha>(_onIniciarEscucha);
    on<HoyRegistroActualizado>(_onRegistroActualizado);
    on<HoyAgregarAgua>(_onAgregarAgua);
    on<HoyGuardarAlimento>(_onGuardarAlimento);
    on<HoyEliminarAlimento>(_onEliminarAlimento);
    on<HoyIniciarAyuno>(_onIniciarAyuno);
    on<HoyRomperAyuno>(_onRomperAyuno);
    on<HoyErrorRecibido>(_onError);
  }

  // ── Handlers ──────────────────────────────────────────────────

  Future<void> _onIniciarEscucha(
      HoyIniciarEscucha event, Emitter<HoyState> emit) async {
    _uid   = event.uid;
    _fecha = event.fecha;
    emit(HoyCargando());

    // Cancelar suscripción anterior si existía
    await _registroSub?.cancel();

    // Suscribirse al Stream de Firestore
    _registroSub = _obtenerRegistro(uid: event.uid, fecha: event.fecha)
        .listen(
          (registro) => add(HoyRegistroActualizado(registro)),
          onError: (e) => add(HoyErrorRecibido(e.toString())),
        );
  }

  void _onRegistroActualizado(
      HoyRegistroActualizado event, Emitter<HoyState> emit) {
    // Leer macros del perfil real del usuario; si no hay, usar defaults keto
    final perfil = _perfilService.perfilActual;
    final tdee   = perfil?.kcal ?? 2100;

    final objetivos = perfil != null
        ? ObjetivosDiariosEntity(
            caloriasObjetivo: perfil.kcal.toDouble(),
            grasasObjetivoG:  perfil.grasasG.toDouble(),
            proteinaObjetivoG: perfil.proteinaG.toDouble(),
            carbosObjetivoG:  perfil.carbosG.toDouble(),
            aguaObjetivoMl:   2500,
          )
        : ObjetivosDiariosEntity.desdeCaloriasKeto(tdee: tdee.toDouble());

    emit(HoyCargado(registro: event.registro, objetivos: objetivos));
  }

  Future<void> _onAgregarAgua(
      HoyAgregarAgua event, Emitter<HoyState> emit) async {
    if (state is! HoyCargado || _uid == null || _fecha == null) return;
    final current = state as HoyCargado;
    final nuevoTotal = current.registro.aguaMl + event.mililitros;

    await _actualizarAgua(
      uid: _uid!,
      fecha: _fecha!,
      aguaMlTotal: nuevoTotal,
    );
    // El Stream de Firestore actualizará el estado automáticamente
  }

  Future<void> _onGuardarAlimento(
      HoyGuardarAlimento event, Emitter<HoyState> emit) async {
    if (_uid == null || _fecha == null) return;

    await _guardarAlimento(
      uid: _uid!,
      fecha: _fecha!,
      alimento: event.alimento,
    );
  }

  Future<void> _onEliminarAlimento(
      HoyEliminarAlimento event, Emitter<HoyState> emit) async {
    if (_uid == null || _fecha == null) return;
    await _eliminarAlimento(
      uid: _uid!,
      fecha: _fecha!,
      alimentoId: event.alimentoId,
    );
    // Firestore Stream actualizará el estado automáticamente
  }

  Future<void> _onIniciarAyuno(
      HoyIniciarAyuno event, Emitter<HoyState> emit) async {
    if (_uid == null || _fecha == null) return;
    await _gestionarAyuno.iniciar(uid: _uid!, fecha: _fecha!);
    // Programar notificaciones de hitos del ayuno
    await NotificationService.instance.programarAyuno(DateTime.now());
  }

  Future<void> _onRomperAyuno(
      HoyRomperAyuno event, Emitter<HoyState> emit) async {
    if (_uid == null || _fecha == null) return;
    await _gestionarAyuno.romper(uid: _uid!, fecha: _fecha!);
    // Cancelar notificaciones de ayuno pendientes
    await NotificationService.instance.cancelarAyuno();
  }

  void _onError(HoyErrorRecibido event, Emitter<HoyState> emit) {
    emit(HoyError(event.mensaje));
  }

  @override
  Future<void> close() {
    _registroSub?.cancel();
    return super.close();
  }
}
