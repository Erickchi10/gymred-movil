import '../models/suscripcion.dart';
import 'api_client.dart';

/// Peticiones de la app del socio (rutas /api/movil/... de la API).
class MovilService {
  final ApiClient api;
  MovilService(this.api);

  /// GET /api/movil/mi-suscripcion (necesita el token).
  Future<EstadoSuscripcion> miSuscripcion() async {
    try {
      final r = await api.dio.get('/movil/mi-suscripcion');
      return EstadoSuscripcion.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }
}
