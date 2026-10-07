/// Usuario que viene de la API.
/// Lo regresan POST /api/auth/login (dentro de "usuario")
/// y GET /api/auth/perfil (este además trae "telefono").
class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol; // 'cliente', 'dueno' o 'admin'
  final String? telefono; // el ? significa que puede venir vacío (null)

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
  });

  /// La app es solo para socios.
  bool get esCliente => rol == 'cliente';

  /// Convierte el JSON de la API en un Usuario.
  /// Los nombres entre comillas deben ser EXACTOS a los de la API.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      telefono: json['telefono'] as String?,
    );
  }
}

/// Respuesta completa de POST /api/auth/login.
class RespuestaLogin {
  final String token;
  final Usuario usuario;

  RespuestaLogin({required this.token, required this.usuario});

  factory RespuestaLogin.fromJson(Map<String, dynamic> json) {
    return RespuestaLogin(
      token: json['token'] as String,
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }
}

