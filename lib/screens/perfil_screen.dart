import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/historial.dart';
import '../models/suscripcion.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';
import 'cambiar_password_screen.dart';
import 'historial_screen.dart';
import 'inicio_screen.dart';
import 'planes_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<_Datos> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_Datos> _cargar() async {
    final movil = context.read<MovilService>();
    final r = await Future.wait([
      movil.miSuscripcion(),
      movil.historial(),
      _telefono(),
    ]);
    return _Datos(
      r[0] as EstadoSuscripcion,
      r[1] as List<ItemHistorial>,
      r[2] as String?,
    );
  }

  /// Pide el teléfono a GET /api/auth/perfil. Si falla, regresa null y la pantalla sigue.
  Future<String?> _telefono() async {
    try {
      final usuario = await context.read<AuthService>().perfil();
      return usuario.telefono;
    } catch (_) {
      return null;
    }
  }

  Future<void> _recargar() async {
    final f = _cargar();
    setState(() {
      _futuro = f;
    });
    try {
      await f;
    } catch (_) {
      // El error ya lo muestra el FutureBuilder.
    }
  }

  /// Abre los planes. Si el socio contrata o cambia de plan, recarga el perfil.
  Future<void> _abrirPlanes(int? idPlanActual) async {
    final contrato = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlanesScreen(idPlanActual: idPlanActual)),
    );
    if (contrato == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: RefreshIndicator(
        color: AppColors.naranja,
        onRefresh: _recargar,
        child: FutureBuilder<_Datos>(
          future: _futuro,
          builder: (context, snap) {
            return ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _Encabezado(
                  nombre: usuario?.nombre ?? '',
                  email: usuario?.email ?? '',
                ),
                const SizedBox(height: 20),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.naranja),
                    ),
                  )
                else if (snap.hasError)
                  Column(
                    children: [
                      Text(snap.error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _recargar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                else
                  _contenido(snap.data!),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().cerrarSesion(),
                  icon: const Icon(Icons.logout, color: AppColors.rojo),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: AppColors.rojo),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _contenido(_Datos datos) {
    final textos = Theme.of(context).textTheme;
    final estado = datos.estado;
    final s = estado.suscripcion;
    final telefono = datos.telefono;
    final gimnasiosVisitados = datos.historial
        .where((i) => i.permitido)
        .map((i) => i.gimnasio)
        .toSet()
        .length;

    return Column(
      children: [
        _TarjetaMembresia(
          estado: estado,
          onPlanes: () => _abrirPlanes(s?.plan.id),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Estadistica(
                valor: '${s?.visitasHoy ?? 0}',
                etiqueta: 'Hoy',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Estadistica(
                valor: '${s?.visitasMes ?? 0}',
                etiqueta: 'Este mes',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Estadistica(
                valor: '$gimnasiosVisitados',
                etiqueta: 'Gimnasios',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mis datos', style: textos.titleMedium),
              const SizedBox(height: 12),
              _Fila(
                icono: Icons.phone_outlined,
                titulo: 'Teléfono',
                valor: (telefono == null || telefono.isEmpty)
                    ? 'No registrado'
                    : telefono,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Tarjeta(
          child: Column(
            children: [
              if (s != null && estado.activa) ...[
                _Opcion(
                  icono: Icons.swap_horiz,
                  texto: 'Cambiar plan',
                  onTap: () => _abrirPlanes(s.plan.id),
                ),
                const Divider(height: 1),
              ],
              _Opcion(
                icono: Icons.history,
                texto: 'Mi historial',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistorialScreen()),
                ),
              ),
              const Divider(height: 1),
              _Opcion(
                icono: Icons.lock_outline,
                texto: 'Cambiar contraseña',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CambiarPasswordScreen()),
                ),
              ),
              const Divider(height: 1),
              _Opcion(
                icono: Icons.info_outline,
                texto: 'Acerca de',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Gymred',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'TacoCoders · ITESCAM',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Datos {
  final EstadoSuscripcion estado;
  final List<ItemHistorial> historial;
  final String? telefono;
  const _Datos(this.estado, this.historial, this.telefono);
}

String _iniciales(String nombre) {
  final partes = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

class _Encabezado extends StatelessWidget {
  final String nombre;
  final String email;
  const _Encabezado({required this.nombre, required this.email});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.naranja,
          child: Text(
            _iniciales(nombre),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(nombre, style: textos.titleLarge),
        Text(
          email,
          style: const TextStyle(color: AppColors.textoSecundario),
        ),
      ],
    );
  }
}

class _TarjetaMembresia extends StatelessWidget {
  final EstadoSuscripcion estado;
  final VoidCallback onPlanes;
  const _TarjetaMembresia({required this.estado, required this.onPlanes});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final s = estado.suscripcion;

    if (!estado.activa || s == null) {
      return _Tarjeta(
        child: Column(
          children: [
            const Icon(Icons.card_membership, size: 40, color: AppColors.naranja),
            const SizedBox(height: 8),
            Text('No tienes una suscripción activa', style: textos.titleMedium),
            const SizedBox(height: 12),
            FilledButton(onPressed: onPlanes, child: const Text('Ver planes')),
          ],
        ),
      );
    }

    final dias = s.diasRestantes;
    final textoDias = dias <= 0
        ? 'Vence hoy'
        : (dias == 1 ? 'Queda 1 día' : 'Quedan $dias días');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.naranja, AppColors.naranjaOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan ${s.plan.nombre}',
                  style: textos.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Activa',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vence el ${fechaLarga(s.fechaFin)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.progreso,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(textoDias, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(
            'Visitas hoy: ${s.visitasHoy}/${s.plan.visitasPorDia}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  final String valor;
  final String etiqueta;
  const _Estadistica({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return _Tarjeta(
      child: Column(
        children: [
          Text(valor, style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  const _Fila({required this.icono, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icono, color: AppColors.naranja),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: textos.bodySmall
                      ?.copyWith(color: AppColors.textoSecundario)),
              const SizedBox(height: 2),
              Text(valor, style: textos.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  const _Opcion({required this.icono, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icono, color: AppColors.naranja),
      title: Text(texto),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textoSecundario),
      onTap: onTap,
    );
  }
}

/// Tarjeta blanca con bordes redondeados.
/// El fondo lo pinta un Material para que los ListTile de adentro
/// tengan dónde dibujar su efecto al tocarlos.
class _Tarjeta extends StatelessWidget {
  final Widget child;
  const _Tarjeta({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}