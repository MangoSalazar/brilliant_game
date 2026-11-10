import 'package:equatable/equatable.dart';

/// Representa a un participante dentro de una sala de espera (Lobby) o partida.
class JugadorSala extends Equatable {
  final String id;
  final String nombre;
  final bool esListo;
  final bool esHost;
  final bool abandono;
  final bool setupListo;
  final bool turnoListo;
  final int puntos;

  const JugadorSala({
    required this.id,
    required this.nombre,
    this.esListo = false,
    this.esHost = false,
    this.abandono = false,
    this.setupListo = false,
    this.turnoListo = false,
    this.puntos = 0,
  });

  JugadorSala copyWith({
    String? id,
    String? nombre,
    bool? esListo,
    bool? esHost,
    bool? abandono,
    bool? setupListo,
    bool? turnoListo,
    int? puntos,
  }) {
    return JugadorSala(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      esListo: esListo ?? this.esListo,
      esHost: esHost ?? this.esHost,
      abandono: abandono ?? this.abandono,
      setupListo: setupListo ?? this.setupListo,
      turnoListo: turnoListo ?? this.turnoListo,
      puntos: puntos ?? this.puntos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'esListo': esListo,
        'esHost': esHost,
        'abandono': abandono,
        'setupListo': setupListo,
        'turnoListo': turnoListo,
        'puntos': puntos,
      };

  factory JugadorSala.fromJson(Map<String, dynamic> json) {
    return JugadorSala(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      esListo: json['esListo'] as bool? ?? false,
      esHost: json['esHost'] as bool? ?? false,
      abandono: json['abandono'] as bool? ?? false,
      setupListo: json['setupListo'] as bool? ?? false,
      turnoListo: json['turnoListo'] as bool? ?? false,
      puntos: json['puntos'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        esListo,
        esHost,
        abandono,
        setupListo,
        turnoListo,
        puntos,
      ];
}
