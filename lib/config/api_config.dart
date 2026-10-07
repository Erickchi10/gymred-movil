/// Configuración de la API. Si cambia el servidor, SOLO se cambia aquí.
class ApiConfig {
  /// Servidor de Josue en Render.
  static const String servidor = 'https://gymred-api.onrender.com';

  /// Todas las rutas de la API empiezan con /api.
  static const String baseUrl = '$servidor/api';

  /// Render gratis "se duerme": la primera petición puede tardar ~1 minuto.
  static const Duration timeout = Duration(seconds: 60);

  /// Las fotos llegan como "/uploads/demo/foto.jpg".
  /// Esta función les pega el servidor adelante para poder mostrarlas.
  static String? urlImagen(String? ruta) {
    if (ruta == null || ruta.isEmpty) return null;
    if (ruta.startsWith('http')) return ruta;
    return '$servidor$ruta';
  }
}
