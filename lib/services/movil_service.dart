import '../models/gimnasio.dart';
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

  /// GET /api/movil/planes (no necesita token).
  Future<List<Plan>> planes() async {
    try {
      final r = await api.dio.get('/movil/planes');
      return (r.data as List)
          .map((p) => Plan.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }

  /// POST /api/movil/suscripcion
  /// Body: { "idPlan": 2, "metodo": "tarjeta" | "transferencia" | "efectivo" }
  /// Regresa el mensaje de la API, por ejemplo "Plan Plus activado".
  Future<String> contratar({
    required int idPlan,
    required String metodo,
  }) async {
    try {
      final r = await api.dio.post(
        '/movil/suscripcion',
        data: {'idPlan': idPlan, 'metodo': metodo},
      );
      final data = r.data as Map<String, dynamic>;
      return data['mensaje'] as String? ?? 'Plan activado';
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }
    /// GET /api/movil/gimnasios (no necesita token).
  Future<List<GimnasioResumen>> gimnasios() async {
    try {
      final r = await api.dio.get('/movil/gimnasios');
      return (r.data as List)
          .map((g) => GimnasioResumen.fromJson(g as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }
}
