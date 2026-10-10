import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/gimnasio.dart';
import '../models/gimnasio_detalle.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import 'inicio_screen.dart' show fechaLarga;

class _Datos {
  final GimnasioDetalle detalle;
  final List<GrupoInventario> inventario;
  _Datos(this.detalle, this.inventario);
}

class DetalleGimnasioScreen extends StatefulWidget {
  final GimnasioResumen gimnasio; // viene de la lista (trae el nivel requerido)
  final int? nivelSocio;

  const DetalleGimnasioScreen({super.key, required this.gimnasio, this.nivelSocio});

  @override
  State<DetalleGimnasioScreen> createState() => _DetalleGimnasioScreenState();
}

class _DetalleGimnasioScreenState extends State<DetalleGimnasioScreen> {
  late Future<_Datos> _futuro;
  String _buscarEquipo = '';

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Datos> _cargar() async {
    final movil = context.read<MovilService>();
    final id = widget.gimnasio.id;
    final r = await Future.wait([movil.detalleGimnasio(id), movil.inventario(id)]);
    return _Datos(r[0] as GimnasioDetalle, r[1] as List<GrupoInventario>);
  }

  void _recargar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gimnasio.nombre)),
      body: FutureBuilder<_Datos>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.naranja));
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snap.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _recargar, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }

          final d = snap.data!.detalle;
          final inventario = snap.data!.inventario;
          final textos = Theme.of(context).textTheme;

          return ListView(
            children: [
              _Fotos(fotos: d.fotos),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Encabezado ----
                    Text(d.nombre, style: textos.headlineMedium?.copyWith(fontSize: 24)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 4),
                        Text(d.totalResenas == 0
                            ? 'Sin reseñas todavía'
                            : '${d.calificacion.toStringAsFixed(1)} · ${d.totalResenas} ${d.totalResenas == 1 ? 'reseña' : 'reseñas'}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Etiqueta(
                          texto: widget.gimnasio.categoriaTexto,
                          fondo: AppColors.azulClaro,
                          color: AppColors.azul,
                        ),
                        etiquetaNivel(widget.gimnasio.nivelRequerido, widget.nivelSocio),
                      ],
                    ),
                    if (d.descripcion != null && d.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(d.descripcion!,
                          style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario)),
                    ],

                    // ---- Información ----
                    _Seccion(
                      titulo: 'Información',
                      child: Column(
                        children: [
                          _Fila(icono: Icons.location_on_outlined, texto: d.direccionCompleta),
                          if (d.telefono != null)
                            _Fila(icono: Icons.phone_outlined, texto: d.telefono!),
                          if (d.capacidadMaxima != null)
                            _Fila(
                                icono: Icons.groups_outlined,
                                texto: 'Capacidad para ${d.capacidadMaxima} personas'),
                        ],
                      ),
                    ),

                    // ---- Horarios ----
                    _Seccion(
                      titulo: 'Horarios',
                      extra: d.abiertoAhora
                          ? const Etiqueta(
                              texto: '● Abierto ahora',
                              fondo: Color(0x1F16A34A),
                              color: AppColors.verde)
                          : const Etiqueta(
                              texto: '● Cerrado ahora',
                              fondo: Color(0x14DC2626),
                              color: AppColors.rojo),
                      child: Column(
                        children: [
                          for (final h in d.horarios)
                            _FilaHorario(h: h, esHoy: h.diaSemana == DateTime.now().weekday),
                        ],
                      ),
                    ),

                    // ---- Servicios ----
                    if (d.servicios.isNotEmpty)
                      _Seccion(
                        titulo: 'Servicios',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final s in d.servicios)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 20, color: AppColors.verde),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.nombre,
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                          if (s.descripcion != null)
                                            Text(s.descripcion!,
                                                style: textos.bodySmall?.copyWith(
                                                    color: AppColors.textoSecundario)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    // ---- Amenidades ----
                    if (d.amenidades.isNotEmpty)
                      _Seccion(
                        titulo: 'Amenidades',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in d.amenidades)
                              Chip(
                                avatar: Icon(_iconoAmenidad(a.icono),
                                    size: 18, color: AppColors.naranja),
                                label: Text(a.nombre),
                                backgroundColor: AppColors.naranjaClaro,
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ),

                    // ---- Equipo (inventario) ----
                    _Seccion(
                      titulo: 'Equipo disponible',
                      child: _Inventario(
                        grupos: inventario,
                        busqueda: _buscarEquipo,
                        onBuscar: (t) {
                          setState(() {
                            _buscarEquipo = t;
                          });
                        },
                      ),
                    ),

                    // ---- Reseñas ----
                    _Seccion(
                      titulo: 'Reseñas',
                      child: d.resenas.isEmpty
                          ? const Text('Aún no hay reseñas de este gimnasio.')
                          : Column(
                              children: [
                                for (final r in d.resenas) _TarjetaResena(r: r),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconoAmenidad(String? icono) {
    switch (icono) {
      case 'shower':
        return Icons.shower_outlined;
      case 'parking':
        return Icons.local_parking;
      case 'lock':
        return Icons.lock_outline;
      case 'wifi':
        return Icons.wifi;
      case 'water':
        return Icons.water_drop_outlined;
      case 'ac':
        return Icons.ac_unit;
      default:
        return Icons.check;
    }
  }
}

// ------------------------------------------------------------------
// Piezas
// ------------------------------------------------------------------

class _Fotos extends StatelessWidget {
  final List<FotoGimnasio> fotos;
  const _Fotos({required this.fotos});

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return const SizedBox(height: 200, child: SinFoto());
    }
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: fotos.length,
        itemBuilder: (context, i) {
          final url = ApiConfig.urlImagen(fotos[i].url);
          return url == null
              ? const SinFoto()
              : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SinFoto());
        },
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  final Widget? extra;
  const _Seccion({required this.titulo, required this.child, this.extra});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              ?extra,
            ],
          ),
          const SizedBox(height: 10),
          Tarjeta(child: child),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Fila({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: AppColors.naranja),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

class _FilaHorario extends StatelessWidget {
  final Horario h;
  final bool esHoy;
  const _FilaHorario({required this.h, required this.esHoy});

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontWeight: esHoy ? FontWeight.w700 : FontWeight.normal,
      color: h.cerrado ? AppColors.textoSecundario : AppColors.texto,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: esHoy
          ? BoxDecoration(color: AppColors.naranjaClaro, borderRadius: BorderRadius.circular(8))
          : null,
      child: Row(
        children: [
          Expanded(child: Text(esHoy ? '${h.nombreDia} (hoy)' : h.nombreDia, style: estilo)),
          Text(h.rango, style: estilo),
        ],
      ),
    );
  }
}

class _Inventario extends StatelessWidget {
  final List<GrupoInventario> grupos;
  final String busqueda;
  final ValueChanged<String> onBuscar;
  const _Inventario({required this.grupos, required this.busqueda, required this.onBuscar});

  @override
  Widget build(BuildContext context) {
    if (grupos.isEmpty) {
      return const Text('Este gimnasio aún no ha registrado su equipo.');
    }

    final q = busqueda.trim().toLowerCase();
    final filtrados = <GrupoInventario>[];
    for (final g in grupos) {
      final equipos = g.equipos
          .where((e) =>
              q.isEmpty ||
              e.nombre.toLowerCase().contains(q) ||
              (e.descripcion ?? '').toLowerCase().contains(q))
          .toList();
      if (equipos.isNotEmpty) {
        filtrados.add(GrupoInventario(categoria: g.categoria, etiqueta: g.etiqueta, equipos: equipos));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: '¿Buscas un aparato? Ej. remo, banca…',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onChanged: onBuscar,
        ),
        const SizedBox(height: 12),
        if (filtrados.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x14DC2626),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Este gimnasio no tiene "$busqueda". Prueba en otro gimnasio afiliado.',
                style: const TextStyle(color: AppColors.rojo)),
          ),
        for (final g in filtrados) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(g.etiqueta.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.naranjaOscuro,
                    letterSpacing: 0.5)),
          ),
          for (final e in g.equipos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (e.descripcion != null && e.descripcion!.isNotEmpty)
                          Text(e.descripcion!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textoSecundario)),
                      ],
                    ),
                  ),
                  Text('×${e.cantidad}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _TarjetaResena extends StatelessWidget {
  final Resena r;
  const _TarjetaResena({required this.r});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.naranjaClaro,
                child: Text(r.cliente.isNotEmpty ? r.cliente[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.naranja, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(r.cliente, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(fechaLarga(r.creadoEn),
                  style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(i <= r.calificacion ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18, color: const Color(0xFFF59E0B)),
            ],
          ),
          if (r.comentario != null && r.comentario!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.comentario!),
          ],
        ],
      ),
    );
  }
}
