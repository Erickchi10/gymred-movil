import '../models/usuario.dart';
import 'api_client.dart';

/// Peticiones de autenticación (rutas /api/auth/... de la API).
class AuthService {
  final ApiClient api;
  AuthService(this.api);

  /// POST /api/auth/login
  /// Body: { "email": "...", "password": "..." }
  Future<RespuestaLogin> login(String email, String password) async {
    try {
      final respuesta = await api.dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      return RespuestaLogin.fromJson(respuesta.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }

  /// GET /api/auth/perfil (necesita el token).
  /// Sirve para revisar si un token guardado todavía funciona.
  Future<Usuario> perfil() async {
    try {
      final respuesta = await api.dio.get('/auth/perfil');
      return Usuario.fromJson(respuesta.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }

    /// POST /api/auth/registro/cliente
  /// Body: { "nombre", "email", "password", "telefono" (opcional) }
  Future<RespuestaLogin> registrarCliente({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    try {
      final respuesta = await api.dio.post('/auth/registro/cliente', data: {
        'nombre': nombre.trim(),
        'email': email.trim(),
        'password': password,
        // El teléfono solo se manda si el usuario lo escribió.
        if (telefono != null && telefono.trim().isNotEmpty) 'telefono': telefono.trim(),
      });
      return RespuestaLogin.fromJson(respuesta.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }
}

