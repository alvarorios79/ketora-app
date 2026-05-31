import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alimento_registrado_entity.dart';

/// El Model es la versión del alimento que sabe leer y escribir Firestore.
/// Extiende la Entity para mantener todos sus campos y lógica,
/// y agrega los métodos de conversión JSON.
class AlimentoRegistradoModel extends AlimentoRegistradoEntity {
  const AlimentoRegistradoModel({
    required super.id,
    required super.nombre,
    required super.cantidadG,
    required super.unidad,
    required super.calorias,
    required super.grasasG,
    required super.proteinaG,
    required super.carbosNetosG,
    required super.comida,
    required super.horaRegistro,
    required super.fuenteRegistro,
  });

  /// Crea el model a partir de un mapa JSON de Firestore
  factory AlimentoRegistradoModel.fromJson(Map<String, dynamic> json) {
    return AlimentoRegistradoModel(
      id:            json['id'] as String,
      nombre:        json['nombre'] as String,
      cantidadG:     (json['cantidadG'] as num).toDouble(),
      unidad:        json['unidad'] as String? ?? 'g',
      calorias:      (json['calorias'] as num).toDouble(),
      grasasG:       (json['grasasG'] as num).toDouble(),
      proteinaG:     (json['proteinaG'] as num).toDouble(),
      carbosNetosG:  (json['carbosNetosG'] as num).toDouble(),
      comida:        json['comida'] as String,
      horaRegistro:  (json['horaRegistro'] as Timestamp).toDate(),
      fuenteRegistro: json['fuenteRegistro'] as String? ?? 'manual',
    );
  }

  /// Convierte el model a mapa JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'id':             id,
      'nombre':         nombre,
      'cantidadG':      cantidadG,
      'unidad':         unidad,
      'calorias':       calorias,
      'grasasG':        grasasG,
      'proteinaG':      proteinaG,
      'carbosNetosG':   carbosNetosG,
      'comida':         comida,
      'horaRegistro':   Timestamp.fromDate(horaRegistro),
      'fuenteRegistro': fuenteRegistro,
    };
  }

  /// Crea el model desde una Entity (para subir a Firestore)
  factory AlimentoRegistradoModel.desdeEntity(AlimentoRegistradoEntity entity) {
    return AlimentoRegistradoModel(
      id:             entity.id,
      nombre:         entity.nombre,
      cantidadG:      entity.cantidadG,
      unidad:         entity.unidad,
      calorias:       entity.calorias,
      grasasG:        entity.grasasG,
      proteinaG:      entity.proteinaG,
      carbosNetosG:   entity.carbosNetosG,
      comida:         entity.comida,
      horaRegistro:   entity.horaRegistro,
      fuenteRegistro: entity.fuenteRegistro,
    );
  }
}
