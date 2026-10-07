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
}
