import '../repositories/i_registro_diario_repository.dart';

/// Caso de uso: iniciar o romper el ayuno del día.
class GestionarAyuno {
  final IRegistroDiarioRepository _repository;

  GestionarAyuno(this._repository);

  Future<void> iniciar({required String uid, required DateTime fecha}) {
    return _repository.iniciarAyuno(
      uid: uid,
      fecha: fecha,
      inicio: DateTime.now(),
    );
  }

  Future<void> romper({required String uid, required DateTime fecha}) {
    return _repository.romperAyuno(
      uid: uid,
      fecha: fecha,
      fin: DateTime.now(),
    );
  }
}
