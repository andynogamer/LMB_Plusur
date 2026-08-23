import 'trivia_model.dart';

class Equipo {
  const Equipo({
    required this.id,
    required this.nombre,
    required this.historia,
    required this.fundacion,
    required this.trivias,
  });

  final String id;
  final String nombre;
  final String historia;
  final int fundacion;
  final List<Trivia> trivias;

  String get displayName => nombre.toUpperCase();

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      historia: json['historia'] as String,
      fundacion: json['fundacion'] as int,
      trivias: (json['trivias'] as List<dynamic>)
          .map((item) => Trivia.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
