import '../repositories/i_registro_diario_repository.dart';

/// Use case: elimina un alimento del registro del día por su ID.
class EliminarAlimento {
  final IRegistroDiarioRepository _repo;
  const EliminarAlimento(this._repo);

  Future<void> call({
    required String uid,
    required DateTime fecha,
    required String alimentoId,
  }) =>
      _repo.eliminarAlimento(uid: uid, fecha: fecha, alimentoId: alimentoId);
}
