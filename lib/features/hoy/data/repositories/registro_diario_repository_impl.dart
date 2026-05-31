import '../../domain/entities/alimento_registrado_entity.dart';
import '../../domain/entities/registro_diario_entity.dart';
import '../../domain/repositories/i_registro_diario_repository.dart';
import '../datasources/firestore_registro_datasource.dart';

/// Implementación concreta del repositorio.
/// Su único trabajo es delegar al datasource y devolver entidades limpias.
/// Si en el futuro agregas caché local (Hive), se añade aquí sin tocar Domain.
class RegistroDiarioRepositoryImpl implements IRegistroDiarioRepository {
  final FirestoreRegistroDatasource _datasource;

  RegistroDiarioRepositoryImpl(this._datasource);

  @override
  Future<RegistroDiarioEntity> obtenerRegistro({
    required String uid,
    required DateTime fecha,
  }) async {
    return _datasource.obtenerRegistro(uid: uid, fecha: fecha);
  }

  @override
  Stream<RegistroDiarioEntity> escucharRegistro({
    required String uid,
    required DateTime fecha,
  }) {
    return _datasource.escucharRegistro(uid: uid, fecha: fecha);
  }

  @override
  Future<void> agregarAlimento({
    required String uid,
    required DateTime fecha,
    required AlimentoRegistradoEntity alimento,
  }) {
    return _datasource.agregarAlimento(
      uid: uid, fecha: fecha, alimento: alimento,
    );
  }

  @override
  Future<void> eliminarAlimento({
    required String uid,
    required DateTime fecha,
    required String alimentoId,
  }) {
    return _datasource.eliminarAlimento(
      uid: uid, fecha: fecha, alimentoId: alimentoId,
    );
  }

  @override
  Future<void> actualizarAgua({
    required String uid,
    required DateTime fecha,
    required int aguaMl,
  }) {
    return _datasource.actualizarAgua(
      uid: uid, fecha: fecha, aguaMl: aguaMl,
    );
  }

  @override
  Future<void> iniciarAyuno({
    required String uid,
    required DateTime fecha,
    required DateTime inicio,
  }) {
    return _datasource.iniciarAyuno(
      uid: uid, fecha: fecha, inicio: inicio,
    );
  }

  @override
  Future<void> romperAyuno({
    required String uid,
    required DateTime fecha,
    required DateTime fin,
  }) {
    return _datasource.romperAyuno(
      uid: uid, fecha: fecha, fin: fin,
    );
  }
}
