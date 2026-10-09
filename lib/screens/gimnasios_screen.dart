import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/gimnasio.dart';
import '../models/suscripcion.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';

/// Lo que necesita la pantalla: los gimnasios y el nivel del plan del socio.
class _Datos {
  final List<GimnasioResumen> gimnasios;
  final int? nivelSocio; // null = sin suscripción activa
  _Datos(this.gimnasios, this.nivelSocio);
}

class GimnasiosScreen extends StatefulWidget {
  const GimnasiosScreen({super.key});

  @override
  State<GimnasiosScreen> createState() => _GimnasiosScreenState();
}

class _GimnasiosScreenState extends State<GimnasiosScreen> {
  late Future<_Datos> _futuro;
  String _busqueda = '';
  String? _categoria; // null = todas

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  /// Pide las dos cosas al mismo tiempo para que cargue más rápido.
  Future<_Datos> _cargar() async {
    final movil = context.read<MovilService>();
    final resultados = await Future.wait([movil.gimnasios(), movil.miSuscripcion()]);
    final gimnasios = resultados[0] as List<GimnasioResumen>;
    final estado = resultados[1] as EstadoSuscripcion;
    return _Datos(gimnasios, estado.activa ? estado.suscripcion?.plan.nivel : null);
  }

  Future<void> _recargar() async {
    final f = _cargar();
    setState(() {
      _futuro = f;
    });
    try {
      await f;
    } catch (_) {}
  }

  List<GimnasioResumen> _filtrar(List<GimnasioResumen> todos) {
    final q = _busqueda.trim().toLowerCase();
    return todos.where((g) {
      final coincideTexto = q.isEmpty ||
          g.nombre.toLowerCase().contains(q) ||
          (g.colonia ?? '').toLowerCase().contains(q) ||
          g.ciudad.toLowerCase().contains(q);
      final coincideCategoria = _categoria == null || g.categoria == _categoria;
      return coincideTexto && coincideCategoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gimnasios')),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre, colonia o ciudad',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (texto) {
                setState(() {
                  _busqueda = texto;
                });
              },
            ),
          ),
          // Filtros por categoría
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _chip('Todos', null),
                for (final c in categorias.entries) _chip(c.value, c.key),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: RefreshIndicator(
              color: AppColors.naranja,
              onRefresh: _recargar,
              child: FutureBuilder<_Datos>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.naranja));
                  }
                  if (snap.hasError) {
                    return ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        Text(snap.error.toString(), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Center(
                          child: OutlinedButton(
                              onPressed: _recargar, child: const Text('Reintentar')),
                        ),
                      ],
                    );
                  }

                  final datos = snap.data!;
                  final lista = _filtrar(datos.gimnasios);

                  if (lista.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(32),
                      children: const [
                        Icon(Icons.search_off, size: 48, color: AppColors.textoSecundario),
                        SizedBox(height: 12),
                        Text('No encontramos gimnasios con ese filtro.',
                            textAlign: TextAlign.center),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _TarjetaGimnasio(
                      g: lista[i],
                      nivelSocio: datos.nivelSocio,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Próximamente: detalle del gimnasio')),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: _categoria == valor,
        selectedColor: AppColors.naranjaClaro,
        onSelected: (_) {
          setState(() {
            _categoria = valor;
          });
        },
      ),
    );
  }
}

class _TarjetaGimnasio extends StatelessWidget {
  final GimnasioResumen g;
  final int? nivelSocio;
  final VoidCallback onTap;

  const _TarjetaGimnasio({required this.g, required this.nivelSocio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final urlFoto = ApiConfig.urlImagen(g.foto);

    return Material(
      color: AppColors.blanco,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto (si no carga, se muestra un ícono)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: urlFoto == null
                  ? const _SinFoto()
                  : Image.network(
                      urlFoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _SinFoto(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(g.nombre,
                            style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(g.calificacion > 0 ? g.calificacion.toStringAsFixed(1) : 'Nuevo'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textoSecundario),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [g.direccion, g.ciudad].where((t) => t.isNotEmpty).join(' · '),
                          style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Etiqueta(
                        texto: g.categoriaTexto,
                        fondo: AppColors.azulClaro,
                        color: AppColors.azul,
                      ),
                      _etiquetaNivel(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compara el nivel del plan del socio con el que pide el gimnasio.
  Widget _etiquetaNivel() {
    if (nivelSocio == null) {
      return _Etiqueta(
        texto: 'Nivel ${g.nivelRequerido}',
        fondo: const Color(0xFFF4F4F5),
        color: AppColors.textoSecundario,
      );
    }
    if (nivelSocio! >= g.nivelRequerido) {
      return const _Etiqueta(
        texto: '✓ Incluido en tu plan',
        fondo: Color(0x1F16A34A),
        color: AppColors.verde,
      );
    }
    return _Etiqueta(
      texto: 'Requiere plan nivel ${g.nivelRequerido}',
      fondo: const Color(0x14DC2626),
      color: AppColors.rojo,
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;
  const _Etiqueta({required this.texto, required this.fondo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _SinFoto extends StatelessWidget {
  const _SinFoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.naranjaClaro,
      child: const Center(
        child: Icon(Icons.fitness_center, size: 40, color: AppColors.naranja),
      ),
    );
  }
}
