import 'package:equatable/equatable.dart';

/// Representa a un participante dentro de una sala de espera (Lobby).
class JugadorSala extends Equatable {
  final String id;
  final String nombre;
  final bool esListo;
  final bool esHost;

  const JugadorSala({
    required this.id,
    required this.nombre,
    this.esListo = false,
    this.esHost = false,
  });

  JugadorSala copyWith({
    String? id,
    String? nombre,
    bool? esListo,
    bool? esHost,
  }) {
    return JugadorSala(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      esListo: esListo ?? this.esListo,
      esHost: esHost ?? this.esHost,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'esListo': esListo,
        'esHost': esHost,
      };

  factory JugadorSala.fromJson(Map<String, dynamic> json) {
    return JugadorSala(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      esListo: json['esListo'] as bool? ?? false,
      esHost: json['esHost'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, nombre, esListo, esHost];
}
