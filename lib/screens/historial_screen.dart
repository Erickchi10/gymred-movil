import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/historial.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<ItemHistorial>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<MovilService>().historial();
  }

  Future<void> _recargar() async {
    final f = context.read<MovilService>().historial();
    setState(() {
      _futuro = f;
    });
    try {
      await f;
    } catch (_) {
      // El error ya lo muestra el FutureBuilder.
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Busca el id del gimnasio por nombre y abre la hoja para calificarlo.
  Future<void> _calificar(ItemHistorial item) async {
    final movil = context.read<MovilService>();
    int? idGimnasio;
    try {
      final gimnasios = await movil.gimnasios();
      for (final g in gimnasios) {
        if (g.nombre == item.gimnasio) idGimnasio = g.id;
      }
    } catch (e) {
      _mensaje(e.toString());
      return;
    }

    final id = idGimnasio;
    if (id == null) {
      _mensaje('No encontramos ese gimnasio.');
      return;
    }
    if (!mounted) return;

    final enviado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaCalificar(idGimnasio: id, nombre: item.gimnasio),
    );

    if (enviado == true) _mensaje('¡Gracias por tu reseña!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: RefreshIndicator(
        color: AppColors.naranja,
        onRefresh: _recargar,
        child: FutureBuilder<List<ItemHistorial>>(
          future: _futuro,
          builder: (context, snap) {
            return ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.naranja),
                    ),
                  )
                else if (snap.hasError)
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      Text(snap.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _recargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                else if (snap.data!.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'Todavía no tienes visitas registradas.\nCuando escanees un QR en un gimnasio, aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textoSecundario),
                    ),
                  )
                else
                  ...snap.data!.map(
                    (item) => _TarjetaVisita(
                      item: item,
                      onCalificar: () => _calificar(item),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaVisita extends StatelessWidget {
  final ItemHistorial item;
  final VoidCallback onCalificar;
  const _TarjetaVisita({required this.item, required this.onCalificar});

  String _fecha(DateTime f) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final hora = f.hour % 12 == 0 ? 12 : f.hour % 12;
    final minuto = f.minute.toString().padLeft(2, '0');
    final periodo = f.hour < 12 ? 'a. m.' : 'p. m.';
    return '${f.day} ${meses[f.month - 1]} ${f.year} · $hora:$minuto $periodo';
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final color = item.permitido ? AppColors.verde : AppColors.rojo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(item.permitido ? Icons.check_circle : Icons.cancel,
              color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.gimnasio, style: textos.titleMedium),
                const SizedBox(height: 2),
                Text(_fecha(item.fecha),
                    style: textos.bodySmall
                        ?.copyWith(color: AppColors.textoSecundario)),
                if (!item.permitido && item.motivo != null) ...[
                  const SizedBox(height: 4),
                  Text(item.motivo!,
                      style: textos.bodySmall?.copyWith(color: color)),
                ],
                if (item.permitido)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onCalificar,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Calificar'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.permitido ? 'Entrada' : 'Denegado',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Hoja para elegir estrellas y escribir un comentario.
class _HojaCalificar extends StatefulWidget {
  final int idGimnasio;
  final String nombre;
  const _HojaCalificar({required this.idGimnasio, required this.nombre});

  @override
  State<_HojaCalificar> createState() => _HojaCalificarState();
}

class _HojaCalificarState extends State<_HojaCalificar> {
  int _estrellas = 5;
  final _comentario = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await context.read<MovilService>().calificarGimnasio(
            idGimnasio: widget.idGimnasio,
            calificacion: _estrellas,
            comentario: _comentario.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Califica a ${widget.nombre}', style: textos.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final n = i + 1;
              return IconButton(
                onPressed: _enviando ? null : () => setState(() => _estrellas = n),
                icon: Icon(
                  n <= _estrellas ? Icons.star : Icons.star_border,
                  size: 40,
                  color: AppColors.naranja,
                ),
              );
            }),
          ),
          TextField(
            controller: _comentario,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.rojo)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.blanco,
                    ),
                  )
                : const Text('Enviar reseña'),
          ),
        ],
      ),
    );
  }
}
