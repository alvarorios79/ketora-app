import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────
enum MensajeRol { usuario, gem }

class GemMensaje extends Equatable {
  final String id;
  final String texto;
  final MensajeRol rol;
  final DateTime timestamp;
  final bool cargando;

  const GemMensaje({
    required this.id,
    required this.texto,
    required this.rol,
    required this.timestamp,
    this.cargando = false,
  });

  @override
  List<Object?> get props => [id, texto, rol, timestamp, cargando];
}

// ── Events ────────────────────────────────────────────────────────────────────
abstract class GemEvent extends Equatable {
  const GemEvent();
  @override
  List<Object?> get props => [];
}

class GemEnviarMensaje extends GemEvent {
  final String texto;
  const GemEnviarMensaje(this.texto);
  @override
  List<Object?> get props => [texto];
}

class GemLimpiarChat extends GemEvent {}

// ── State ─────────────────────────────────────────────────────────────────────
class GemState extends Equatable {
  final List<GemMensaje> mensajes;
  final bool enviando;
  final String? error;

  const GemState({
    this.mensajes = const [],
    this.enviando = false,
    this.error,
  });

  GemState copyWith({
    List<GemMensaje>? mensajes,
    bool? enviando,
    String? error,
  }) {
    return GemState(
      mensajes: mensajes ?? this.mensajes,
      enviando: enviando ?? this.enviando,
      error: error,
    );
  }

  @override
  List<Object?> get props => [mensajes, enviando, error];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class GemBloc extends Bloc<GemEvent, GemState> {
  // TODO: inyectar GemRepository con Gemini 1.5 Flash

  GemBloc() : super(const GemState(mensajes: [
    GemMensaje(
      id: 'bienvenida',
      texto: '¡Hola! Soy GEM, tu coach keto 🥑\n\n'
          '¿En qué puedo ayudarte hoy?',
      rol: MensajeRol.gem,
      timestamp: _epoch,
    ),
  ])) {
    on<GemEnviarMensaje>(_onEnviarMensaje);
    on<GemLimpiarChat>(_onLimpiarChat);
  }

  // Timestamp fijo para el mensaje de bienvenida
  static final DateTime _epoch = DateTime(2024, 1, 1);

  Future<void> _onEnviarMensaje(GemEnviarMensaje event, Emitter<GemState> emit) async {
    final msgUsuario = GemMensaje(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      texto: event.texto,
      rol: MensajeRol.usuario,
      timestamp: DateTime.now(),
    );

    // Placeholder de carga
    final msgCargando = GemMensaje(
      id: 'cargando',
      texto: '',
      rol: MensajeRol.gem,
      timestamp: DateTime.now(),
      cargando: true,
    );

    emit(state.copyWith(
      mensajes: [...state.mensajes, msgUsuario, msgCargando],
      enviando: true,
    ));

    try {
      // TODO: llamar a GemRepository.chat(messages, context: userProfile)
      await Future.delayed(const Duration(seconds: 1));

      final respuesta = GemMensaje(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        texto: 'Respuesta de GEM sobre: "${event.texto}"\n\n'
            '(Aquí irá la respuesta real de Gemini 1.5 Flash)',
        rol: MensajeRol.gem,
        timestamp: DateTime.now(),
      );

      final sin_cargando = state.mensajes
          .where((m) => m.id != 'cargando')
          .toList();

      emit(state.copyWith(
        mensajes: [...sin_cargando, respuesta],
        enviando: false,
      ));
    } catch (e) {
      final sin_cargando = state.mensajes
          .where((m) => m.id != 'cargando')
          .toList();
      emit(state.copyWith(
        mensajes: sin_cargando,
        enviando: false,
        error: 'No pude conectar con GEM. Revisa tu conexión.',
      ));
    }
  }

  void _onLimpiarChat(GemLimpiarChat event, Emitter<GemState> emit) {
    emit(const GemState());
  }
}
