import 'package:equatable/equatable.dart';

/// Representa a un participante dentro de una sala de espera (Lobby) o partida.
class JugadorSala extends Equatable {
  final String id;
  final String nombre;
  final bool esListo;
  final bool esHost;
  final bool abandono;

  const JugadorSala({
    required this.id,
    required this.nombre,
    this.esListo = false,
    this.esHost = false,
    this.abandono = false,
  });

  JugadorSala copyWith({
    String? id,
    String? nombre,
    bool? esListo,
    bool? esHost,
    bool? abandono,
  }) {
    return JugadorSala(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      esListo: esListo ?? this.esListo,
      esHost: esHost ?? this.esHost,
      abandono: abandono ?? this.abandono,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'esListo': esListo,
        'esHost': esHost,
        'abandono': abandono,
      };

  factory JugadorSala.fromJson(Map<String, dynamic> json) {
    return JugadorSala(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      esListo: json['esListo'] as bool? ?? false,
      esHost: json['esHost'] as bool? ?? false,
      abandono: json['abandono'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, nombre, esListo, esHost, abandono];
}
