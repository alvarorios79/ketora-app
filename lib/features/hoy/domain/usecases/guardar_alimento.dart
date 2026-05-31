import '../entities/alimento_registrado_entity.dart';
import '../repositories/i_registro_diario_repository.dart';

/// Caso de uso: guardar un alimento en el registro del día.
/// Se llama cuando el usuario confirma un alimento desde el modal del +.
class GuardarAlimento {
  final IRegistroDiarioRepository _repository;

  GuardarAlimento(this._repository);

  Future<void> call({
    required String uid,
    required DateTime fecha,
    required AlimentoRegistradoEntity alimento,
  }) {
    return _repository.agregarAlimento(
      uid: uid,
      fecha: fecha,
      alimento: alimento,
    );
  }
}
