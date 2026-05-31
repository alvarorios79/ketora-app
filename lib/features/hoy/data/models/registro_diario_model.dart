import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/registro_diario_entity.dart';
import '../../domain/entities/alimento_registrado_entity.dart';
import 'alimento_registrado_model.dart';

/// Model del registro diario — sabe leer y escribir en Firestore.
///
/// Estructura del documento en Firestore:
/// registros_diarios/{uid}_{YYYY-MM-DD}
/// {
///   uid: string,
///   fecha: string,           // "2026-05-29"
///   aguaMl: number,
///   ayuno: {
///     activo: boolean,
///     inicio: Timestamp?,
///     fin: Timestamp?,
///   },
///   alimentos: [ AlimentoRegistradoModel... ],
///   resumen: {               // calculado al guardar, para consultas rápidas
///     caloriasTotal: number,
///     grasasTotal: number,
///     proteinaTotal: number,
///     carbosTotal: number,
///   }
/// }
class RegistroDiarioModel extends RegistroDiarioEntity {
  const RegistroDiarioModel({
    required super.uid,
    required super.fecha,
    required super.alimentos,
    required super.aguaMl,
    required super.ayunoActivo,
    super.ayunoInicio,
    super.ayunoFin,
  });

  /// Lee el documento de Firestore y construye el model
  factory RegistroDiarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Parsear lista de alimentos
    final alimentosJson = data['alimentos'] as List<dynamic>? ?? [];
    final alimentos = alimentosJson
        .map((a) => AlimentoRegistradoModel.fromJson(a as Map<String, dynamic>))
        .toList();

    // Parsear ayuno
    final ayunoData = data['ayuno'] as Map<String, dynamic>? ?? {};

    // Extraer uid y fecha del docId si no están en el documento
    final docParts = doc.id.split('_');
    final uidFallback = docParts.isNotEmpty ? docParts.first : 'desconocido';
    final fechaFallback = DateTime.now();

    return RegistroDiarioModel(
      uid:         (data['uid'] as String?) ?? uidFallback,
      fecha:       data['fecha'] != null
          ? DateTime.parse(data['fecha'] as String)
          : fechaFallback,
      alimentos:   alimentos,
      aguaMl:      (data['aguaMl'] as num?)?.toInt() ?? 0,
      ayunoActivo: ayunoData['activo'] as bool? ?? false,
      ayunoInicio: ayunoData['inicio'] != null
          ? (ayunoData['inicio'] as Timestamp).toDate()
          : null,
      ayunoFin: ayunoData['fin'] != null
          ? (ayunoData['fin'] as Timestamp).toDate()
          : null,
    );
  }

  /// Prepara el mapa para guardar en Firestore (documento completo)
  Map<String, dynamic> toFirestore() {
    final alimentosModels = alimentos
        .map((a) => AlimentoRegistradoModel.desdeEntity(a).toJson())
        .toList();

    return {
      'uid':    uid,
      'fecha':  _formatFecha(fecha),
      'aguaMl': aguaMl,
      'ayuno': {
        'activo': ayunoActivo,
        'inicio': ayunoInicio != null ? Timestamp.fromDate(ayunoInicio!) : null,
        'fin':    ayunoFin != null ? Timestamp.fromDate(ayunoFin!) : null,
      },
      'alimentos': alimentosModels,
      // Resumen pre-calculado para consultas rápidas en progreso mensual
      'resumen': {
        'caloriasTotal': caloriasTotal,
        'grasasTotal':   grasasTotal,
        'proteinaTotal': proteinaTotal,
        'carbosTotal':   carbosTotal,
      },
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
  }

  /// Crea un registro vacío para el día de hoy (cuando el usuario no ha registrado nada)
  factory RegistroDiarioModel.vacio({
    required String uid,
    required DateTime fecha,
  }) {
    return RegistroDiarioModel(
      uid:         uid,
      fecha:       fecha,
      alimentos:   const [],
      aguaMl:      0,
      ayunoActivo: false,
    );
  }

  static String _formatFecha(DateTime fecha) =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  /// ID del documento en Firestore: {uid}_{YYYY-MM-DD}
  static String docId({required String uid, required DateTime fecha}) =>
      '${uid}_${_formatFecha(fecha)}';
}
