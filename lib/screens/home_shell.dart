import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'gimnasios_screen.dart';
import 'inicio_screen.dart';

/// Contenedor principal con la barra de navegación de abajo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  // IndexedStack mantiene viva cada pestaña (no se recarga al regresar).
  static const _pantallas = [
    InicioScreen(),
    GimnasiosScreen(),
    _Provisional(
      titulo: 'Historial',
      icono: Icons.history,
      texto: 'Aquí verás tus visitas a los gimnasios.',
    ),
    _PerfilProvisional(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Solo deja salir de la app si ya estás en Inicio.
      canPop: _indice == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _indice = 0; // si estabas en otra pestaña, regresa a Inicio
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _indice, children: _pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          indicatorColor: AppColors.naranjaClaro,
          backgroundColor: AppColors.blanco,
          onDestinationSelected: (i) {
            setState(() {
              _indice = i;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.naranja),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on, color: AppColors.naranja),
              label: 'Gimnasios',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history, color: AppColors.naranja),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.naranja),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla temporal para las pestañas que aún no hacemos.
class _Provisional extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String texto;
  const _Provisional({
    required this.titulo,
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 56, color: AppColors.naranja),
              const SizedBox(height: 12),
              Text(texto, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              const Text(
                'Próximamente',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilProvisional extends StatelessWidget {
  const _PerfilProvisional();

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.naranjaClaro,
              child: Icon(Icons.person, size: 40, color: AppColors.naranja),
            ),
            const SizedBox(height: 12),
            Text(
              usuario?.nombre ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              usuario?.email ?? '',
              style: const TextStyle(color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().cerrarSesion(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
