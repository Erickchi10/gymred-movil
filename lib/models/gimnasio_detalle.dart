/// Ficha completa de GET /api/movil/gimnasios/{id}
class GimnasioDetalle {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? calle;
  final String? colonia;
  final String ciudad;
  final String? estado;
  final String? codigoPostal;
  final String? telefono;
  final int? capacidadMaxima;
  final String categoria;
  final double? latitud;
  final double? longitud;
  final List<Horario> horarios;
  final List<FotoGimnasio> fotos;
  final List<Servicio> servicios;
  final List<Amenidad> amenidades;
  final double calificacion;
  final int totalResenas;
  final List<Resena> resenas;

  GimnasioDetalle({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.calle,
    this.colonia,
    required this.ciudad,
    this.estado,
    this.codigoPostal,
    this.telefono,
    this.capacidadMaxima,
    required this.categoria,
    this.latitud,
    this.longitud,
    required this.horarios,
    required this.fotos,
    required this.servicios,
    required this.amenidades,
    required this.calificacion,
    required this.totalResenas,
    required this.resenas,
  });

  factory GimnasioDetalle.fromJson(Map<String, dynamic> json) {
    List<T> lista<T>(String clave, T Function(Map<String, dynamic>) convertir) =>
        ((json[clave] as List?) ?? [])
            .map((e) => convertir(e as Map<String, dynamic>))
            .toList();

    final horarios = lista('horarios', Horario.fromJson)
      ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));
    final fotos = lista('fotos', FotoGimnasio.fromJson)
      ..sort((a, b) => a.orden.compareTo(b.orden));

    return GimnasioDetalle(
      id: _aInt(json['id']),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      calle: json['calle'] as String?,
      colonia: json['colonia'] as String?,
      ciudad: json['ciudad'] as String? ?? '',
      estado: json['estado'] as String?,
      codigoPostal: json['codigoPostal'] as String?,
      telefono: json['telefono'] as String?,
      capacidadMaxima: json['capacidadMaxima'] == null ? null : _aInt(json['capacidadMaxima']),
      categoria: json['categoria'] as String? ?? 'gimnasio',
      latitud: _aDouble(json['latitud']),
      longitud: _aDouble(json['longitud']),
      horarios: horarios,
      fotos: fotos,
      servicios: lista('servicios', Servicio.fromJson).where((s) => s.activo).toList(),
      amenidades: lista('amenidades', Amenidad.fromJson),
      calificacion: _aDouble(json['calificacion']) ?? 0,
      totalResenas: _aInt(json['totalResenas'] ?? 0),
      resenas: lista('resenas', Resena.fromJson),
    );
  }

  /// "Calle 59 #412, Centro, Merida, Yucatan, CP 97000"
  String get direccionCompleta => [
        calle,
        colonia,
        ciudad,
        estado,
        if (codigoPostal != null) 'CP $codigoPostal',
      ].where((t) => t != null && t.trim().isNotEmpty).join(', ');

  /// Horario de hoy (null si no hay datos).
  Horario? get horarioHoy {
    final hoy = DateTime.now().weekday; // 1 = lunes ... 7 = domingo (igual que la API)
    for (final h in horarios) {
      if (h.diaSemana == hoy) return h;
    }
    return null;
  }

  bool get abiertoAhora => horarioHoy?.abiertoA(DateTime.now()) ?? false;
}

class Horario {
  final int diaSemana; // 1 = lunes ... 7 = domingo
  final String? horaApertura; // "05:30:00"
  final String? horaCierre;
  final bool cerrado;

  Horario({required this.diaSemana, this.horaApertura, this.horaCierre, required this.cerrado});

  factory Horario.fromJson(Map<String, dynamic> json) => Horario(
        diaSemana: _aInt(json['diaSemana']),
        horaApertura: json['horaApertura'] as String?,
        horaCierre: json['horaCierre'] as String?,
        cerrado: json['cerrado'] == true || json['cerrado'] == 1,
      );

  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  String get nombreDia => _dias[(diaSemana - 1).clamp(0, 6)];

  /// "05:30 – 22:00" o "Cerrado"
  String get rango {
    if (cerrado || horaApertura == null || horaCierre == null) return 'Cerrado';
    return '${horaApertura!.substring(0, 5)} – ${horaCierre!.substring(0, 5)}';
  }

  /// ¿Está abierto a esa hora? Compara textos "HH:mm".
  bool abiertoA(DateTime momento) {
    if (cerrado || horaApertura == null || horaCierre == null) return false;
    final ahora = '${momento.hour.toString().padLeft(2, '0')}:${momento.minute.toString().padLeft(2, '0')}';
    return ahora.compareTo(horaApertura!.substring(0, 5)) >= 0 &&
        ahora.compareTo(horaCierre!.substring(0, 5)) < 0;
  }
}

class FotoGimnasio {
  final String url;
  final String? descripcion;
  final int orden;

  FotoGimnasio({required this.url, this.descripcion, required this.orden});

  factory FotoGimnasio.fromJson(Map<String, dynamic> json) => FotoGimnasio(
        url: json['url'] as String,
        descripcion: json['descripcion'] as String?,
        orden: _aInt(json['orden'] ?? 0),
      );
}

class Servicio {
  final String nombre;
  final String? descripcion;
  final bool activo;

  Servicio({required this.nombre, this.descripcion, required this.activo});

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        activo: json['activo'] != false && json['activo'] != 0,
      );
}

class Amenidad {
  final String nombre;
  final String? icono; // "shower", "parking", "lock"...

  Amenidad({required this.nombre, this.icono});

  factory Amenidad.fromJson(Map<String, dynamic> json) => Amenidad(
        nombre: json['nombre'] as String,
        icono: json['icono'] as String?,
      );
}

class Resena {
  final int calificacion;
  final String? comentario;
  final DateTime creadoEn;
  final String cliente;

  Resena({required this.calificacion, this.comentario, required this.creadoEn, required this.cliente});

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        calificacion: _aInt(json['calificacion']),
        comentario: json['comentario'] as String?,
        // OJO: viene como "creado_en" (guion bajo) y en hora UTC
        creadoEn: DateTime.parse(json['creado_en'] as String).toLocal(),
        cliente: json['cliente'] as String? ?? 'Socio',
      );
}

/// Inventario de GET /api/movil/gimnasios/{id}/inventario
class GrupoInventario {
  final String categoria; // peso_libre, maquinas, cardio, funcional, clases, otro
  final String etiqueta; // "Peso libre", "Máquinas"...
  final List<Equipo> equipos;

  GrupoInventario({required this.categoria, required this.etiqueta, required this.equipos});

  factory GrupoInventario.fromJson(Map<String, dynamic> json) => GrupoInventario(
        categoria: json['categoria'] as String,
        etiqueta: json['etiqueta'] as String? ?? json['categoria'] as String,
        equipos: ((json['equipos'] as List?) ?? [])
            .map((e) => Equipo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Equipo {
  final String nombre;
  final String? descripcion;
  final int cantidad;

  Equipo({required this.nombre, this.descripcion, required this.cantidad});

  factory Equipo.fromJson(Map<String, dynamic> json) => Equipo(
        nombre: (json['nombre'] as String).trim(),
        descripcion: (json['descripcion'] as String?)?.trim(),
        cantidad: _aInt(json['cantidad'] ?? 1),
      );
}

// ---- Ayudantes ----
int _aInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

double? _aDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

