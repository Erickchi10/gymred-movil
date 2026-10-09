/// Plan de la plataforma (viene dentro de la suscripción y en GET /api/movil/planes).
class Plan {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precioMensual;
  final int nivel; // el gimnasio exige un nivel mínimo (nivel_requerido)
  final int visitasPorDia;
  final int? visitasPorMes; // null = ilimitadas (plan Elite)

  Plan({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precioMensual,
    required this.nivel,
    required this.visitasPorDia,
    this.visitasPorMes,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precioMensual: _aDouble(json['precioMensual']),
      nivel: json['nivel'] as int,
      visitasPorDia: json['visitasPorDia'] as int,
      visitasPorMes: json['visitasPorMes'] as int?,
    );
  }
}

/// Suscripción vigente del socio.
class Suscripcion {
  final int id;
  final Plan plan;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int visitasHoy;
  final int visitasMes;
  final int visitasRestantesHoy;

  Suscripcion({
    required this.id,
    required this.plan,
    required this.fechaInicio,
    required this.fechaFin,
    required this.visitasHoy,
    required this.visitasMes,
    required this.visitasRestantesHoy,
  });

  factory Suscripcion.fromJson(Map<String, dynamic> json) {
    return Suscripcion(
      id: json['id'] as int,
      plan: Plan.fromJson(json['plan'] as Map<String, dynamic>),
      fechaInicio: _aFecha(json['fechaInicio']),
      fechaFin: _aFecha(json['fechaFin']),
      visitasHoy: json['visitasHoy'] as int,
      visitasMes: json['visitasMes'] as int,
      visitasRestantesHoy: json['visitasRestantesHoy'] as int,
    );
  }

  /// Días que faltan para que venza (0 = vence hoy).
  int get diasRestantes {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    return fechaFin.difference(hoy).inDays;
  }

  /// Duración total del periodo (normalmente 30 días).
  int get diasTotales {
    final d = fechaFin.difference(fechaInicio).inDays;
    return d <= 0 ? 1 : d;
  }

  /// Qué tanto le queda (1.0 = recién contratada, 0.0 = por vencer).
  double get progreso => (diasRestantes / diasTotales).clamp(0.0, 1.0);

  /// La asesora pidió avisar 2 o 3 días antes.
  bool get porVencer => diasRestantes <= 3;
}

/// Respuesta completa de GET /api/movil/mi-suscripcion.
class EstadoSuscripcion {
  final bool activa;
  final Suscripcion? suscripcion;

  EstadoSuscripcion({required this.activa, this.suscripcion});

  factory EstadoSuscripcion.fromJson(Map<String, dynamic> json) {
    final s = json['suscripcion'];
    return EstadoSuscripcion(
      activa: json['activa'] as bool,
      suscripcion: s == null ? null : Suscripcion.fromJson(s as Map<String, dynamic>),
    );
  }
}

// ---- Ayudantes ----

/// El precio puede llegar como número (699) o como texto ("699.00").
double _aDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse('$valor') ?? 0;
}

/// Las fechas llegan como "2026-10-18". Tomamos solo la fecha, sin hora,
/// para que no se corra un día por la zona horaria.
DateTime _aFecha(dynamic valor) {
  final texto = '$valor';
  return DateTime.parse(texto.length >= 10 ? texto.substring(0, 10) : texto);
}
