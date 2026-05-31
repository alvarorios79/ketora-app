import '../repositories/i_registro_diario_repository.dart';

/// Caso de uso: sumar mililitros de agua al registro del día.
class ActualizarAgua {
  final IRegistroDiarioRepository _repository;

  ActualizarAgua(this._repository);

  Future<void> call({
    required String uid,
    required DateTime fecha,
    required int aguaMlTotal,
  }) {
    return _repository.actualizarAgua(
      uid: uid,
      fecha: fecha,
      aguaMl: aguaMlTotal,
    );
  }
}
