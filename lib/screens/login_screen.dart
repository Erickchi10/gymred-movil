import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus(); // esconde el teclado
    if (!_formulario.currentState!.validate()) return;
    // Si sale bien, main.dart cambia solo a la pantalla de inicio.
    await context.read<AuthProvider>().login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.fitness_center, size: 64, color: AppColors.naranja),
                  const SizedBox(height: 12),
                  Text('Gymred', textAlign: TextAlign.center, style: textos.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Entra a cualquier gimnasio afiliado',
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
                  ),
                  const SizedBox(height: 32),

                  // Correo (mismas reglas que valida la API)
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (valor) {
                      final texto = valor?.trim() ?? '';
                      if (texto.isEmpty) return 'Escribe tu correo';
                      if (!texto.contains('@') || !texto.contains('.')) {
                        return 'Escribe un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: _password,
                    obscureText: _ocultarPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => auth.cargando ? null : _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                      ),
                    ),
                    validator: (valor) => (valor == null || valor.length < 6)
                        ? 'La contraseña debe tener al menos 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Mensaje de error de la API
                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x14DC2626), // rojo muy clarito
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(auth.error!, style: const TextStyle(color: AppColors.rojo)),
                    ),
                  const SizedBox(height: 16),

                  // Botón
                  FilledButton(
                    onPressed: auth.cargando ? null : _entrar,
                    child: auth.cargando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                                    if (auth.cargando) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Conectando con el servidor… la primera vez puede tardar hasta un minuto.',
                      textAlign: TextAlign.center,
                      style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
                    ),
                  ],

                  // Enlace para crear cuenta (fuera del "if", siempre visible)
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      TextButton(
                        onPressed: auth.cargando
                            ? null
                            : () {
                                context.read<AuthProvider>().limpiarError();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                                );
                              },
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}