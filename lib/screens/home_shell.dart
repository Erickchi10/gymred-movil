import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'gimnasios_screen.dart';
import 'historial_screen.dart';
import 'inicio_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';

/// Contenedor principal con la barra de navegación de abajo.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  // Sube cada vez que entras a Historial o Perfil, para que recarguen sus datos.
  int _generacion = 0;

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      const InicioScreen(),
      const GimnasiosScreen(),
      const MapaScreen(),
      HistorialScreen(key: ValueKey('historial-$_generacion')),
      PerfilScreen(key: ValueKey('perfil-$_generacion')),
    ];

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
        // IndexedStack mantiene viva cada pestaña (Mapa y Gimnasios no se recargan).
        body: IndexedStack(index: _indice, children: pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          indicatorColor: AppColors.naranjaClaro,
          backgroundColor: AppColors.blanco,
          onDestinationSelected: (i) {
            setState(() {
              _indice = i;
              if (i == 3 || i == 4) _generacion++;
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
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppColors.naranja),
              label: 'Mapa',
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
