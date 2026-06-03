import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo plano del perfil de usuario persistido en Firestore.
class PerfilUsuario {
  final String uid;
  final String nombre;
  final String objetivo;
  final String sexo;
  final int edad;
  final double pesoKg;
  final double alturaCm;
  final String actividad;
  final String experiencia;
  final String tipoAyuno;
  final int kcal;
  final int grasasG;
  final int proteinaG;
  final int carbosG;
  final DateTime fechaRegistro;
  // Ventana de alimentación programada
  final int horaInicioComida; // hora en que rompe el ayuno (ej: 12 = 12:00pm)
  final int minInicioComida;  // minutos (ej: 30 = 12:30pm)
  final int horaFinComida;    // hora en que termina de comer (ej: 19 = 7:00pm)
  final int minFinComida;

  const PerfilUsuario({
    required this.uid,
    required this.nombre,
    required this.objetivo,
    required this.sexo,
    required this.edad,
    required this.pesoKg,
    required this.alturaCm,
    required this.actividad,
    required this.experiencia,
    required this.tipoAyuno,
    required this.kcal,
    required this.grasasG,
    required this.proteinaG,
    required this.carbosG,
    required this.fechaRegistro,
    this.horaInicioComida = 12,
    this.minInicioComida  = 0,
    this.horaFinComida    = 20,
    this.minFinComida     = 0,
  });

  /// Duración del ayuno en horas
  double get horasAyuno {
    final inicio = horaFinComida * 60 + minFinComida;
    final fin    = horaInicioComida * 60 + minInicioComida;
    final diff   = fin <= inicio ? (fin + 1440) - inicio : fin - inicio;
    return diff / 60;
  }

  /// Etiqueta de la ventana: "12:00 — 20:00 (16h ayuno)"
  String get etiquetaVentana {
    final ini = '${horaInicioComida.toString().padLeft(2,'0')}:${minInicioComida.toString().padLeft(2,'0')}';
    final fin = '${horaFinComida.toString().padLeft(2,'0')}:${minFinComida.toString().padLeft(2,'0')}';
    return '$ini — $fin';
  }

  factory PerfilUsuario.fromMap(String uid, Map<String, dynamic> m) {
    return PerfilUsuario(
      uid: uid,
      nombre:      m['nombre']     as String? ?? 'Usuario',
      objetivo:    m['objetivo']   as String? ?? 'Perder peso',
      sexo:        m['sexo']       as String? ?? 'Masculino',
      edad:        (m['edad']      as num?)?.toInt()    ?? 30,
      pesoKg:      (m['pesoKg']    as num?)?.toDouble() ?? 80,
      alturaCm:    (m['alturaCm']  as num?)?.toDouble() ?? 170,
      actividad:   m['actividad']  as String? ?? 'Ligero',
      experiencia: m['experiencia'] as String? ?? 'Primera vez',
      tipoAyuno:   m['tipoAyuno']  as String? ?? (m['ayuno'] == true ? '16:8' : 'sin_ayuno'),
      kcal:        (m['kcal']      as num?)?.toInt()    ?? 2100,
      grasasG:     (m['grasasG']   as num?)?.toInt()    ?? 163,
      proteinaG:   (m['proteinaG'] as num?)?.toInt()    ?? 131,
      carbosG:     (m['carbosG']   as num?)?.toInt()    ?? 26,
      fechaRegistro: m['fechaRegistro'] != null
          ? (m['fechaRegistro'] as Timestamp).toDate()
          : DateTime.now(),
      horaInicioComida: (m['horaInicioComida'] as num?)?.toInt() ?? 12,
      minInicioComida:  (m['minInicioComida']  as num?)?.toInt() ?? 0,
      horaFinComida:    (m['horaFinComida']    as num?)?.toInt() ?? 20,
      minFinComida:     (m['minFinComida']     as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre':      nombre,
    'objetivo':    objetivo,
    'sexo':        sexo,
    'edad':        edad,
    'pesoKg':      pesoKg,
    'alturaCm':    alturaCm,
    'actividad':   actividad,
    'experiencia': experiencia,
    'tipoAyuno':   tipoAyuno,
    'kcal':        kcal,
    'grasasG':     grasasG,
    'proteinaG':   proteinaG,
    'carbosG':     carbosG,
    'fechaRegistro':    Timestamp.fromDate(fechaRegistro),
    'horaInicioComida': horaInicioComida,
    'minInicioComida':  minInicioComida,
    'horaFinComida':    horaFinComida,
    'minFinComida':     minFinComida,
  };

  PerfilUsuario copyWith({
    String? nombre,
    String? objetivo,
    String? sexo,
    int?    edad,
    double? pesoKg,
    double? alturaCm,
    String? actividad,
    String? experiencia,
    String? tipoAyuno,
    int?    kcal,
    int?    grasasG,
    int?    proteinaG,
    int?    carbosG,
    int?    horaInicioComida,
    int?    minInicioComida,
    int?    horaFinComida,
    int?    minFinComida,
  }) => PerfilUsuario(
    uid:          uid,
    nombre:       nombre       ?? this.nombre,
    objetivo:     objetivo     ?? this.objetivo,
    sexo:         sexo         ?? this.sexo,
    edad:         edad         ?? this.edad,
    pesoKg:       pesoKg       ?? this.pesoKg,
    alturaCm:     alturaCm     ?? this.alturaCm,
    actividad:    actividad    ?? this.actividad,
    experiencia:  experiencia  ?? this.experiencia,
    tipoAyuno:    tipoAyuno    ?? this.tipoAyuno,
    kcal:         kcal         ?? this.kcal,
    grasasG:      grasasG      ?? this.grasasG,
    proteinaG:    proteinaG    ?? this.proteinaG,
    carbosG:      carbosG      ?? this.carbosG,
    fechaRegistro:    fechaRegistro,
    horaInicioComida: horaInicioComida ?? this.horaInicioComida,
    minInicioComida:  minInicioComida  ?? this.minInicioComida,
    horaFinComida:    horaFinComida    ?? this.horaFinComida,
    minFinComida:     minFinComida     ?? this.minFinComida,
  );
}

/// Servicio singleton que gestiona el perfil del usuario en Firestore.
/// Mantiene en memoria el perfil activo para uso sin await en toda la app.
class PerfilService {
  final FirebaseFirestore _db;
  PerfilUsuario? _perfil;

  PerfilService({required FirebaseFirestore db}) : _db = db;

  PerfilUsuario? get perfilActual => _perfil;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  /// Carga el perfil del usuario desde Firestore. Retorna null si no existe.
  Future<PerfilUsuario?> cargarPerfil(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      _perfil = PerfilUsuario.fromMap(uid, doc.data()!);
      return _perfil;
    } catch (_) {
      return null;
    }
  }

  /// Guarda (o actualiza) el perfil del usuario en Firestore.
  Future<void> guardarPerfil(PerfilUsuario perfil) async {
    _perfil = perfil;
    await _col.doc(perfil.uid).set(perfil.toMap(), SetOptions(merge: true));
  }

  /// Actualiza campos específicos del perfil sin reescribir todo el documento.
  Future<void> actualizarCampos(String uid, Map<String, dynamic> campos) async {
    await _col.doc(uid).update(campos);
    if (_perfil != null) {
      // Actualizar cache local
      _perfil = PerfilUsuario.fromMap(uid, {
        ..._perfil!.toMap(),
        ...campos,
      });
    }
  }

  /// Stream en tiempo real del perfil del usuario.
  Stream<PerfilUsuario?> perfilStream(String uid) {
    return _col.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      _perfil = PerfilUsuario.fromMap(uid, snap.data()!);
      return _perfil;
    });
  }

  /// Verifica si el usuario ya completó el onboarding.
  Future<bool> onboardingCompletado(String uid) async {
    final perfil = await cargarPerfil(uid);
    return perfil != null;
  }
}
