import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gimnasio.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';
import 'detalle_gimnasio_screen.dart';

/// Mapa con un pin por cada gimnasio afiliado.
/// Al tocar un pin aparece una tarjeta con su dirección y botones para ver la ficha o cómo llegar.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // Centro inicial: Mérida, Yucatán.
  static const _centroInicial = LatLng(20.9674, -89.5926);

  late Future<List<GimnasioResumen>> _futuro;
  GimnasioResumen? _seleccionado;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<GimnasioResumen>> _cargar() {
    return context.read<MovilService>().gimnasios();
  }

  void _recargar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  void _abrirFicha(GimnasioResumen g) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleGimnasioScreen(gimnasio: g),
      ),
    );
  }

  Future<void> _comoLlegar(GimnasioResumen g) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${g.latitud},${g.longitud}',
    );
    final abrio = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!abrio && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa del teléfono.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de gimnasios')),
      body: FutureBuilder<List<GimnasioResumen>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.naranja),
            );
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
                    OutlinedButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Solo los gimnasios que tienen coordenadas.
          final conUbicacion = snap.data!
              .where((g) => g.latitud != null && g.longitud != null)
              .toList();

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _centroInicial,
                  initialZoom: 13,
                  // Tocar el mapa vacío cierra la tarjeta.
                  onTap: (_, _) {
                    setState(() {
                      _seleccionado = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.gymred_movil',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final g in conUbicacion)
                        Marker(
                          point: LatLng(g.latitud!, g.longitud!),
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _seleccionado = g;
                              });
                            },
                            child: Icon(
                              Icons.location_on,
                              color: _seleccionado?.id == g.id
                                  ? AppColors.azul
                                  : AppColors.naranja,
                              size: 44,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _seleccionado == null
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            conUbicacion.isEmpty
                                ? 'Ningún gimnasio tiene ubicación todavía.'
                                : '${conUbicacion.length} gimnasios · toca un pin para ver su ubicación',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _TarjetaMapa(
                        gimnasio: _seleccionado!,
                        onFicha: () => _abrirFicha(_seleccionado!),
                        onLlegar: () => _comoLlegar(_seleccionado!),
                        onCerrar: () {
                          setState(() {
                            _seleccionado = null;
                          });
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaMapa extends StatelessWidget {
  final GimnasioResumen gimnasio;
  final VoidCallback onFicha;
  final VoidCallback onLlegar;
  final VoidCallback onCerrar;

  const _TarjetaMapa({
    required this.gimnasio,
    required this.onFicha,
    required this.onLlegar,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final direccion = gimnasio.direccion.isEmpty
        ? 'Sin dirección todavía'
        : gimnasio.direccion;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gimnasio.nombre,
                    style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCerrar,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.naranja),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    direccion,
                    style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFicha,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Ver ficha'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onLlegar,
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
