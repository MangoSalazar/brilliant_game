import 'package:equatable/equatable.dart';

/// Modelo de entidad que representa a un usuario autenticado en el sistema.
class Usuario extends Equatable {
  final String id;
  final String username;

  const Usuario({
    required this.id,
    required this.username,
  });

  @override
  List<Object?> get props => [id, username];

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
      };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        username: json['username'] as String,
      );
}
