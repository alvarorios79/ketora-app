import 'package:equatable/equatable.dart';

/// Un alimento que el usuario registró en un momento del día.
/// Esta clase no sabe nada de Firestore ni de JSON — solo representa el dato.
class AlimentoRegistradoEntity extends Equatable {
  final String id;
  final String nombre;
  final double cantidadG;       // gramos consumidos
  final String unidad;          // 'g', 'ml', 'pieza', 'taza', etc.
  final double calorias;
  final double grasasG;
  final double proteinaG;
  final double carbosNetosG;
  final String comida;          // 'desayuno' | 'almuerzo' | 'cena' | 'snack'
  final DateTime horaRegistro;
  final String fuenteRegistro;  // 'busqueda' | 'codigo_barras' | 'foto_ia' | 'manual'

  const AlimentoRegistradoEntity({
    required this.id,
    required this.nombre,
    required this.cantidadG,
    required this.unidad,
    required this.calorias,
    required this.grasasG,
    required this.proteinaG,
    required this.carbosNetosG,
    required this.comida,
    required this.horaRegistro,
    required this.fuenteRegistro,
  });

  /// Clase keto según el semáforo de KETORA (g de carbos por 100g)
  String get claseKeto {
    final carbsPor100g = cantidadG > 0 ? (carbosNetosG / cantidadG) * 100 : 0;
    if (carbsPor100g <= 5)  return 'A';
    if (carbsPor100g <= 15) return 'B';
    if (carbsPor100g <= 25) return 'C';
    return 'F';
  }

  @override
  List<Object?> get props => [
    id, nombre, cantidadG, unidad, calorias,
    grasasG, proteinaG, carbosNetosG, comida,
    horaRegistro, fuenteRegistro,
  ];
}
