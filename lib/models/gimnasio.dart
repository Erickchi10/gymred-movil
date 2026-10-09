/// Gimnasio en la lista de GET /api/movil/gimnasios.
class GimnasioResumen {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? calle;
  final String? colonia;
  final String ciudad;
  final String categoria; // gimnasio, crossfit, yoga, box, funcional
  final double? latitud;
  final double? longitud;
  final int nivelRequerido; // nivel de plan mínimo para entrar
  final double? distanciaKm; // solo viene si se manda lat/lng
  final String? foto; // ruta tipo "/uploads/demo/energy-1.jpg"
  final double calificacion; // promedio de reseñas (0 = sin reseñas)

  GimnasioResumen({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.calle,
    this.colonia,
    required this.ciudad,
    required this.categoria,
    this.latitud,
    this.longitud,
    required this.nivelRequerido,
    this.distanciaKm,
    this.foto,
    required this.calificacion,
  });

  factory GimnasioResumen.fromJson(Map<String, dynamic> json) {
    return GimnasioResumen(
      id: _aInt(json['id']),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      calle: json['calle'] as String?,
      colonia: json['colonia'] as String?,
      ciudad: json['ciudad'] as String? ?? '',
      categoria: json['categoria'] as String? ?? 'gimnasio',
      latitud: _aDouble(json['latitud']),
      longitud: _aDouble(json['longitud']),
      // OJO: estos dos vienen con guion bajo desde la API
      nivelRequerido: _aInt(json['nivel_requerido'] ?? 1),
      distanciaKm: _aDouble(json['distancia_km']),
      foto: json['foto'] as String?,
      calificacion: _aDouble(json['calificacion']) ?? 0,
    );
  }

  /// "Calle 33 #145, Buenavista"
  String get direccion => [calle, colonia]
      .where((t) => t != null && t.trim().isNotEmpty)
      .join(', ');

  String get categoriaTexto => categorias[categoria] ?? categoria;
}

/// Categorías que maneja la API (las mismas del panel web).
const categorias = {
  'gimnasio': 'Gimnasio',
  'crossfit': 'CrossFit',
  'yoga': 'Yoga',
  'box': 'Box',
  'funcional': 'Funcional',
};

// ---- Ayudantes: MySQL a veces manda números como texto ----

int _aInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

double? _aDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

