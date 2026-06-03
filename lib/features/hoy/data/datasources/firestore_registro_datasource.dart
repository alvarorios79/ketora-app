import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alimento_registrado_entity.dart';
import '../models/alimento_registrado_model.dart';
import '../models/registro_diario_model.dart';

/// El datasource es el único lugar que toca Firestore directamente.
/// Nada más en el proyecto importa cloud_firestore — solo esta clase.
class FirestoreRegistroDatasource {
  final FirebaseFirestore _db;

  FirestoreRegistroDatasource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Referencia a la colección — users/{uid}/registros_diarios/{fecha}
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('registros_diarios');

  DocumentReference<Map<String, dynamic>> _docRef(
      String uid, DateTime fecha) =>
      _col(uid).doc(fecha.toIso8601String().substring(0, 10));

  // ── Leer un registro ─────────────────────────────────────────

  Future<RegistroDiarioModel> obtenerRegistro({
    required String uid,
    required DateTime fecha,
  }) async {
    final doc = await _docRef(uid, fecha).get();

    if (!doc.exists) {
      // El usuario no ha registrado nada hoy — devolvemos registro vacío
      return RegistroDiarioModel.vacio(uid: uid, fecha: fecha);
    }

    return RegistroDiarioModel.fromFirestore(doc);
  }

  // ── Escuchar en tiempo real ───────────────────────────────────

  Stream<RegistroDiarioModel> escucharRegistro({
    required String uid,
    required DateTime fecha,
  }) {
    return _docRef(uid, fecha).snapshots().map((doc) {
      if (!doc.exists) {
        return RegistroDiarioModel.vacio(uid: uid, fecha: fecha);
      }
      return RegistroDiarioModel.fromFirestore(doc);
    });
  }

  // ── Agregar alimento ─────────────────────────────────────────

  Future<void> agregarAlimento({
    required String uid,
    required DateTime fecha,
    required AlimentoRegistradoEntity alimento,
  }) async {
    final ref = _docRef(uid, fecha);
    final alimentoJson = AlimentoRegistradoModel.desdeEntity(alimento).toJson();

    // arrayUnion agrega el alimento sin sobrescribir los demás
    // setMerge crea el documento si no existe
    await ref.set({
      'uid':   uid,
      'fecha': RegistroDiarioModel.docId(uid: uid, fecha: fecha).split('_').last,
      'alimentos': FieldValue.arrayUnion([alimentoJson]),
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Eliminar alimento ────────────────────────────────────────

  Future<void> eliminarAlimento({
    required String uid,
    required DateTime fecha,
    required String alimentoId,
  }) async {
    // Firestore no permite arrayRemove con un ID parcial,
    // así que leemos, filtramos y volvemos a escribir
    final doc = await _docRef(uid, fecha).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final alimentos = (data['alimentos'] as List<dynamic>? ?? [])
        .where((a) => (a as Map<String, dynamic>)['id'] != alimentoId)
        .toList();

    await _docRef(uid, fecha).update({
      'alimentos': alimentos,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  // ── Actualizar agua ──────────────────────────────────────────

  Future<void> actualizarAgua({
    required String uid,
    required DateTime fecha,
    required int aguaMl,
  }) async {
    await _docRef(uid, fecha).set({
      'uid':    uid,
      'aguaMl': aguaMl,
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Ayuno ────────────────────────────────────────────────────

  Future<void> iniciarAyuno({
    required String uid,
    required DateTime fecha,
    required DateTime inicio,
  }) async {
    await _docRef(uid, fecha).set({
      'uid': uid,
      'ayuno': {
        'activo': true,
        'inicio': Timestamp.fromDate(inicio),
        'fin': null,
      },
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> romperAyuno({
    required String uid,
    required DateTime fecha,
    required DateTime fin,
  }) async {
    await _docRef(uid, fecha).set({
      'uid': uid,
      'ayuno': {
        'activo': false,
        'fin': Timestamp.fromDate(fin),
      },
      'actualizadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
