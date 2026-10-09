import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/suscripcion.dart';
import '../providers/auth_provider.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';
import 'planes_screen.dart';

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// "18 de octubre"
String fechaLarga(DateTime f) => '${f.day} de ${_meses[f.month - 1]}';

void _proximamente(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<EstadoSuscripcion> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<MovilService>().miSuscripcion();
  }

  /// Vuelve a pedir los datos (al jalar hacia abajo, en "Reintentar" o al contratar).
  Future<void> _recargar() async {
    final f = context.read<MovilService>().miSuscripcion();
        setState(() {
      _futuro = f;
    });
    try {
      await f;
    } catch (_) {
      // El error ya lo muestra el FutureBuilder.
    }
  }

  /// Abre la pantalla de planes. Si el socio contrata, recarga el inicio.
  Future<void> _abrirPlanes({int? idPlanActual}) async {
    final contrato = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlanesScreen(idPlanActual: idPlanActual)),
    );
    if (contrato == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre = (usuario?.nombre ?? '').trim().split(' ').first;
    final primerNombre =
        nombre.isEmpty ? '' : nombre[0].toUpperCase() + nombre.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gymred'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.naranja,
        onRefresh: _recargar,
        child: FutureBuilder<EstadoSuscripcion>(
          future: _futuro,
          builder: (context, snap) {
            return ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text('Hola, $primerNombre 👋',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                if (snap.connectionState == ConnectionState.waiting)
                  const _Cargando()
                else if (snap.hasError)
                  _ErrorCarga(mensaje: snap.error.toString(), onReintentar: _recargar)
                else
                  ..._contenido(snap.data!),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _contenido(EstadoSuscripcion estado) {
    final s = estado.suscripcion;

    // Sin suscripción (nunca contrató o ya venció)
    if (!estado.activa || s == null) {
      return [
        _SinSuscripcion(onVerPlanes: () => _abrirPlanes()),
        const SizedBox(height: 16),
        const _BotonQr(
          habilitado: false,
          motivo: 'Necesitas una suscripción activa para entrar a un gimnasio.',
        ),
      ];
    }

    // Con suscripción
    return [
      _TarjetaSuscripcion(s: s),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => _abrirPlanes(idPlanActual: s.plan.id),
          child: const Text('Cambiar de plan'),
        ),
      ),
      if (s.porVencer) ...[
        _AvisoVencimiento(
          dias: s.diasRestantes,
          onRenovar: () => _abrirPlanes(idPlanActual: s.plan.id),
        ),
        const SizedBox(height: 16),
      ],
      _BotonQr(
        habilitado: s.visitasRestantesHoy > 0,
        motivo: 'Ya usaste tus visitas de hoy. Vuelve mañana.',
      ),
    ];
  }
}

// ------------------------------------------------------------------
// Piezas de la pantalla
// ------------------------------------------------------------------

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.naranja),
          SizedBox(height: 16),
          Text(
            'Cargando tu suscripción…\nSi el servidor estaba dormido puede tardar hasta un minuto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.textoSecundario),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con bordes redondeados.
class _Tarjeta extends StatelessWidget {
  final Widget child;
  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _TarjetaSuscripcion extends StatelessWidget {
  final Suscripcion s;
  const _TarjetaSuscripcion({required this.s});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final dias = s.diasRestantes;
    final textoDias =
        dias <= 0 ? 'Vence hoy' : (dias == 1 ? 'Queda 1 día' : 'Quedan $dias días');

    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Plan ${s.plan.nombre}', style: textos.titleLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1F16A34A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.verde),
                    SizedBox(width: 6),
                    Text('Activa',
                        style: TextStyle(color: AppColors.verde, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Vence el ${fechaLarga(s.fechaFin)}',
              style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.progreso,
              minHeight: 8,
              color: s.porVencer ? AppColors.rojo : AppColors.naranja,
              backgroundColor: AppColors.naranjaClaro,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(textoDias, style: textos.bodySmall),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  titulo: 'Hoy',
                  valor: '${s.visitasHoy}/${s.plan.visitasPorDia}',
                  unidad: 'visitas',
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE4E4E7)),
              const SizedBox(width: 16),
              Expanded(
                child: _Dato(
                  titulo: 'Este mes',
                  valor: '${s.visitasMes}',
                  unidad: s.plan.visitasPorMes == null
                      ? 'visitas (ilimitadas)'
                      : 'de ${s.plan.visitasPorMes} visitas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String titulo;
  final String valor;
  final String unidad;
  const _Dato({required this.titulo, required this.valor, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: valor, style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          TextSpan(text: ' $unidad', style: textos.bodySmall),
        ])),
      ],
    );
  }
}

class _AvisoVencimiento extends StatelessWidget {
  final int dias;
  final VoidCallback onRenovar;
  const _AvisoVencimiento({required this.dias, required this.onRenovar});

  @override
  Widget build(BuildContext context) {
    final texto = dias <= 0
        ? 'Tu suscripción vence hoy. Renuévala para no perder el acceso.'
        : 'Tu suscripción vence en $dias ${dias == 1 ? 'día' : 'días'}. Renuévala para no perder el acceso.';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.naranjaClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.naranja),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.naranjaOscuro),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
          TextButton(onPressed: onRenovar, child: const Text('Renovar')),
        ],
      ),
    );
  }
}

class _SinSuscripcion extends StatelessWidget {
  final VoidCallback onVerPlanes;
  const _SinSuscripcion({required this.onVerPlanes});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return _Tarjeta(
      child: Column(
        children: [
          const Icon(Icons.card_membership, size: 48, color: AppColors.naranja),
          const SizedBox(height: 12),
          Text('No tienes una suscripción activa',
              textAlign: TextAlign.center, style: textos.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Contrata un plan para entrar a cualquier gimnasio afiliado de la región.',
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onVerPlanes, child: const Text('Ver planes')),
        ],
      ),
    );
  }
}

class _BotonQr extends StatelessWidget {
  final bool habilitado;
  final String motivo;
  const _BotonQr({required this.habilitado, required this.motivo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: habilitado
              ? () => _proximamente(context, 'Próximamente: escanear el QR del gimnasio')
              : null,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Escanear QR'),
        ),
        if (!habilitado) ...[
          const SizedBox(height: 8),
          Text(motivo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSecundario)),
        ],
      ],
    );
  }
}

