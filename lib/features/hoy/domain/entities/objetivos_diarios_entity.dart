import 'package:equatable/equatable.dart';

/// Las metas diarias del usuario, calculadas con Mifflin-St Jeor
/// y guardadas en su perfil de Firestore.
class ObjetivosDiariosEntity extends Equatable {
  final double caloriasObjetivo;
  final double grasasObjetivoG;
  final double proteinaObjetivoG;
  final double carbosObjetivoG;
  final int aguaObjetivoMl;

  const ObjetivosDiariosEntity({
    required this.caloriasObjetivo,
    required this.grasasObjetivoG,
    required this.proteinaObjetivoG,
    required this.carbosObjetivoG,
    required this.aguaObjetivoMl,
  });

  /// Calcula los objetivos a partir de TDEE usando distribución keto 70/25/5
  factory ObjetivosDiariosEntity.desdeCaloriasKeto({
    required double tdee,
    int aguaObjetivoMl = 2500,
  }) {
    // 1g grasa = 9 kcal | 1g proteína = 4 kcal | 1g carbo = 4 kcal
    return ObjetivosDiariosEntity(
      caloriasObjetivo: tdee,
      grasasObjetivoG: (tdee * 0.70) / 9,
      proteinaObjetivoG: (tdee * 0.25) / 4,
      carbosObjetivoG: (tdee * 0.05) / 4,
      aguaObjetivoMl: aguaObjetivoMl,
    );
  }

  @override
  List<Object?> get props => [
    caloriasObjetivo, grasasObjetivoG,
    proteinaObjetivoG, carbosObjetivoG, aguaObjetivoMl,
  ];
}
