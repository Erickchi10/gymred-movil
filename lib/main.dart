import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Se crean una sola vez y los comparte toda la app.
  final storage = TokenStorage();
  final api = ApiClient(storage);
  final authService = AuthService(api);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api), // lo usarán las demás pantallas
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, storage, api)..revisarSesion(),
        ),
      ],
      child: const GymredApp(),
    ),
  );
}

class GymredApp extends StatelessWidget {
  const GymredApp({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.select<AuthProvider, EstadoSesion>((a) => a.estado);

    return MaterialApp(
      title: 'Gymred',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      // La pantalla cambia sola según haya sesión o no.
      home: switch (estado) {
        EstadoSesion.revisando => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        EstadoSesion.sinSesion => const LoginScreen(),
        EstadoSesion.conSesion => const _InicioProvisional(),
      },
    );
  }
}

/// Pantalla temporal para probar el login.
/// En el siguiente paso la cambiamos por el Inicio real (mi suscripción).
class _InicioProvisional extends StatelessWidget {
  const _InicioProvisional();

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
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
      body: Center(
        child: Text('Hola, ${usuario?.nombre ?? ''} 👋',
            style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
