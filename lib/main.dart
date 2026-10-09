import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/movil_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Se crean una sola vez y los comparte toda la app.
  final storage = TokenStorage();
  final api = ApiClient(storage);
  final authService = AuthService(api);
  final movilService = MovilService(api);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<MovilService>.value(value: movilService),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authService, storage, api)..revisarSesion(),
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
        EstadoSesion.conSesion => const HomeShell(),
      },
    );
  }
}
