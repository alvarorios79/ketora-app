import '../entities/registro_diario_entity.dart';
import '../repositories/i_registro_diario_repository.dart';

/// Caso de uso: obtener el registro de comidas de un día específico.
/// El BLoC llama esto al cargar la pantalla Hoy.
class ObtenerRegistroDiario {
  final IRegistroDiarioRepository _repository;

  ObtenerRegistroDiario(this._repository);

  /// Devuelve un Stream para que el Dashboard se actualice en tiempo real.
  Stream<RegistroDiarioEntity> call({
    required String uid,
    required DateTime fecha,
  }) {
    return _repository.escucharRegistro(uid: uid, fecha: fecha);
  }
}
