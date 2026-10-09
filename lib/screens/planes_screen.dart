import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/suscripcion.dart';
import '../services/api_client.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';

/// Métodos que acepta la API (ENUM de la tabla "pagos").
const _metodos = {
  'tarjeta': 'Tarjeta',
  'transferencia': 'Transferencia',
  'efectivo': 'Efectivo',
};

class PlanesScreen extends StatefulWidget {
  /// Id del plan que ya tiene el socio (para marcarlo como "Tu plan actual").
  final int? idPlanActual;
  const PlanesScreen({super.key, this.idPlanActual});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  late Future<List<Plan>> _futuro;
  int? _seleccionado;
  String _metodo = 'tarjeta';
  bool _contratando = false;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<MovilService>().planes();
    _seleccionado = widget.idPlanActual;
  }

  void _recargar() {
        setState(() {
      _futuro = context.read<MovilService>().planes();
    });
  }

  String _precio(Plan p) => '\$${p.precioMensual.toStringAsFixed(0)}';

  Future<void> _contratar(Plan plan) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar contratación'),
        content: Text(
          'Plan ${plan.nombre} por ${_precio(plan)} al mes, '
          'pagando con ${_metodos[_metodo]!.toLowerCase()}.\n\n'
          'Si ya tienes un plan, se reemplaza por este. '
          'El nuevo dura 30 días a partir de hoy.\n\n'
          'Es un pago simulado: no se hace ningún cargo real.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Contratar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _contratando = true);
    try {
      final mensaje = await context
          .read<MovilService>()
          .contratar(idPlan: plan.id, metodo: _metodo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $mensaje')));
      Navigator.pop(context, true); // true = sí contrató, el inicio se recarga
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _contratando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: FutureBuilder<List<Plan>>(
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

          final planes = snap.data!;
          final elegido = planes.where((p) => p.id == _seleccionado).firstOrNull;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Con una sola suscripción entras a todos los gimnasios afiliados de tu nivel.',
                      style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 16),
                    for (final plan in planes) ...[
                      _TarjetaPlan(
                        plan: plan,
                        precio: _precio(plan),
                        seleccionado: plan.id == _seleccionado,
                        esActual: plan.id == widget.idPlanActual,
                        onTap: () => setState(() => _seleccionado = plan.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    Text('Método de pago', style: textos.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in _metodos.entries)
                          ChoiceChip(
                            label: Text(m.value),
                            selected: _metodo == m.key,
                            selectedColor: AppColors.naranjaClaro,
                            onSelected: (_) => setState(() => _metodo = m.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pago simulado: en esta versión no se hace ningún cargo real.',
                      style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
                    ),
                  ],
                ),
              ),
              // Botón fijo abajo
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton(
                    onPressed: (elegido == null || _contratando) ? null : () => _contratar(elegido),
                    child: _contratando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(elegido == null
                            ? 'Elige un plan'
                            : elegido.id == widget.idPlanActual
                                ? 'Renovar ${elegido.nombre} · ${_precio(elegido)}/mes'
                                : 'Contratar ${elegido.nombre} · ${_precio(elegido)}/mes'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  final Plan plan;
  final String precio;
  final bool seleccionado;
  final bool esActual;
  final VoidCallback onTap;

  const _TarjetaPlan({
    required this.plan,
    required this.precio,
    required this.seleccionado,
    required this.esActual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final niveles = plan.nivel == 1 ? 'Gimnasios de nivel 1' : 'Gimnasios de nivel 1 a ${plan.nivel}';
    final visitasMes = plan.visitasPorMes == null
        ? 'Visitas ilimitadas al mes'
        : 'Hasta ${plan.visitasPorMes} visitas al mes';
    final visitasDia = plan.visitasPorDia == 1 ? '1 visita por día' : '${plan.visitasPorDia} visitas por día';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.naranja : const Color(0xFFE4E4E7),
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  seleccionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppColors.naranja,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(plan.nombre, style: textos.titleLarge)),
                Text(precio,
                    style: textos.titleLarge?.copyWith(
                        color: AppColors.naranja, fontWeight: FontWeight.w700)),
                Text(' /mes', style: textos.bodySmall),
              ],
            ),
            if (esActual) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.azulClaro,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Tu plan actual',
                    style: TextStyle(color: AppColors.azul, fontWeight: FontWeight.w600)),
              ),
            ],
            if (plan.descripcion != null) ...[
              const SizedBox(height: 8),
              Text(plan.descripcion!,
                  style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario)),
            ],
            const SizedBox(height: 8),
            for (final b in [visitasDia, visitasMes, niveles])
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: AppColors.verde),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

