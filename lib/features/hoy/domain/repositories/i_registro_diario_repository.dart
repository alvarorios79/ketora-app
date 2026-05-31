import '../entities/registro_diario_entity.dart';
import '../entities/alimento_registrado_entity.dart';

/// Contrato que define QUÉ puede hacer el repositorio de registros.
/// La capa Domain no sabe si los datos vienen de Firestore, de una API
/// o de una base de datos local — eso es problema de la capa Data.
abstract class IRegistroDiarioRepository {

  /// Obtiene el registro del día indicado para el usuario.
  /// Si no existe, devuelve un registro vacío (nunca null).
  Future<RegistroDiarioEntity> obtenerRegistro({
    required String uid,
    required DateTime fecha,
  });

  /// Escucha cambios en tiempo real del registro del día.
  /// Útil para que el Dashboard se actualice automáticamente.
  Stream<RegistroDiarioEntity> escucharRegistro({
    required String uid,
    required DateTime fecha,
  });

  /// Agrega un alimento al registro del día.
  Future<void> agregarAlimento({
    required String uid,
    required DateTime fecha,
    required AlimentoRegistradoEntity alimento,
  });

  /// Elimina un alimento del registro del día por su ID.
  Future<void> eliminarAlimento({
    required String uid,
    required DateTime fecha,
    required String alimentoId,
  });

  /// Actualiza el total de agua del día.
  Future<void> actualizarAgua({
    required String uid,
    required DateTime fecha,
    required int aguaMl,
  });

  /// Registra el inicio del ayuno.
  Future<void> iniciarAyuno({
    required String uid,
    required DateTime fecha,
    required DateTime inicio,
  });

  /// Registra el fin del ayuno.
  Future<void> romperAyuno({
    required String uid,
    required DateTime fecha,
    required DateTime fin,
  });
}
