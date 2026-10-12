import 'package:flutter/material.dart';
import '../models/gimnasio_detalle.dart';
import '../theme/app_theme.dart';

/// Pantalla con todo el equipo del gimnasio: buscador + lista agrupada.
/// Recibe los grupos que ya cargó la ficha, así no hace otra petición.
class EquipoScreen extends StatefulWidget {
  final String nombreGimnasio;
  final List<GrupoInventario> grupos;

  const EquipoScreen({
    super.key,
    required this.nombreGimnasio,
    required this.grupos,
  });

  @override
  State<EquipoScreen> createState() => _EquipoScreenState();
}

class _EquipoScreenState extends State<EquipoScreen> {
  String _buscar = '';

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final q = _buscar.trim().toLowerCase();

    // Filtra por nombre o descripción y quita los grupos que quedan vacíos.
    final filtrados = <GrupoInventario>[];
    for (final g in widget.grupos) {
      final equipos = g.equipos
          .where((e) =>
              q.isEmpty ||
              e.nombre.toLowerCase().contains(q) ||
              (e.descripcion ?? '').toLowerCase().contains(q))
          .toList();
      if (equipos.isNotEmpty) {
        filtrados.add(
          GrupoInventario(categoria: g.categoria, etiqueta: g.etiqueta, equipos: equipos),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Equipo · ${widget.nombreGimnasio}')),
      body: widget.grupos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Este gimnasio aún no ha registrado su equipo.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: '¿Buscas un aparato? Ej. remo, banca…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (t) {
                    setState(() {
                      _buscar = t;
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (filtrados.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x14DC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Este gimnasio no tiene "$_buscar". Prueba en otro gimnasio afiliado.',
                      style: const TextStyle(color: AppColors.rojo),
                    ),
                  ),

                for (final g in filtrados) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Text(
                      g.etiqueta.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.naranja,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.blanco,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < g.equipos.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(g.equipos[i].nombre,
                                          style: textos.bodyLarge
                                              ?.copyWith(fontWeight: FontWeight.w600)),
                                      if (g.equipos[i].descripcion != null &&
                                          g.equipos[i].descripcion!.isNotEmpty)
                                        Text(
                                          g.equipos[i].descripcion!,
                                          style: const TextStyle(
                                              fontSize: 12, color: AppColors.textoSecundario),
                                        ),
                                    ],
                                  ),
                                ),
                                Text('×${g.equipos[i].cantidad}',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
