import 'package:equatable/equatable.dart';
import 'alimento_registrado_entity.dart';

/// El registro completo de un día del usuario.
/// Contiene todos sus alimentos, agua y estado del ayuno.
class RegistroDiarioEntity extends Equatable {
  final String uid;
  final DateTime fecha;
  final List<AlimentoRegistradoEntity> alimentos;
  final int aguaMl;
  final bool ayunoActivo;
  final DateTime? ayunoInicio;
  final DateTime? ayunoFin;

  const RegistroDiarioEntity({
    required this.uid,
    required this.fecha,
    required this.alimentos,
    required this.aguaMl,
    required this.ayunoActivo,
    this.ayunoInicio,
    this.ayunoFin,
  });

  // ── Totales calculados ──────────────────────────────────────

  double get caloriasTotal =>
      alimentos.fold(0, (sum, a) => sum + a.calorias);

  double get grasasTotal =>
      alimentos.fold(0, (sum, a) => sum + a.grasasG);

  double get proteinaTotal =>
      alimentos.fold(0, (sum, a) => sum + a.proteinaG);

  double get carbosTotal =>
      alimentos.fold(0, (sum, a) => sum + a.carbosNetosG);

  /// Alimentos filtrados por comida del día
  List<AlimentoRegistradoEntity> alimentosDe(String comida) =>
      alimentos.where((a) => a.comida == comida).toList();

  /// Horas transcurridas desde que inició el ayuno
  Duration? get duracionAyuno {
    if (!ayunoActivo || ayunoInicio == null) return null;
    return DateTime.now().difference(ayunoInicio!);
  }

  /// Copia del registro con campos modificados
  RegistroDiarioEntity copyWith({
    List<AlimentoRegistradoEntity>? alimentos,
    int? aguaMl,
    bool? ayunoActivo,
    DateTime? ayunoInicio,
    DateTime? ayunoFin,
  }) {
    return RegistroDiarioEntity(
      uid: uid,
      fecha: fecha,
      alimentos: alimentos ?? this.alimentos,
      aguaMl: aguaMl ?? this.aguaMl,
      ayunoActivo: ayunoActivo ?? this.ayunoActivo,
      ayunoInicio: ayunoInicio ?? this.ayunoInicio,
      ayunoFin: ayunoFin ?? this.ayunoFin,
    );
  }

  @override
  List<Object?> get props => [
    uid, fecha, alimentos, aguaMl,
    ayunoActivo, ayunoInicio, ayunoFin,
  ];
}
