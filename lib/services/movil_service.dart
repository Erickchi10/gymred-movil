import '../models/gimnasio.dart';
import '../models/suscripcion.dart';
import 'api_client.dart';
import '../models/gimnasio_detalle.dart';

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

  /// GET /api/movil/gimnasios?buscar=&categoria=&lat=&lng=
  /// Si mandas lat y lng, la API regresa distanciaKm y ordena por cercanía.
  Future<List<GimnasioResumen>> gimnasios({
    String? buscar,
    String? categoria,
    double? lat,
    double? lng,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (buscar != null && buscar.trim().isNotEmpty) {
        query['buscar'] = buscar.trim();
      }
      if (categoria != null) query['categoria'] = categoria;
      if (lat != null && lng != null) {
        query['lat'] = lat;
        query['lng'] = lng;
      }
      final r = await api.dio.get('/movil/gimnasios', queryParameters: query);
      return (r.data as List)
          .map((g) => GimnasioResumen.fromJson(g as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }

  /// GET /api/movil/gimnasios/{id}
  Future<GimnasioDetalle> detalleGimnasio(int id) async {
    try {
      final r = await api.dio.get('/movil/gimnasios/$id');
      return GimnasioDetalle.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }

  /// GET /api/movil/gimnasios/{id}/inventario
  Future<List<GrupoInventario>> inventario(int id) async {
    try {
      final r = await api.dio.get('/movil/gimnasios/$id/inventario');
      return (r.data as List)
          .map((g) => GrupoInventario.fromJson(g as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.traducirError(e);
    }
  }
}
