import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  bool _ocultarPassword = true;
  bool _ocultarConfirmar = true;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _registrarme() async {
    FocusScope.of(context).unfocus();
    if (!_formulario.currentState!.validate()) return;

    final ok = await context.read<AuthProvider>().registrar(
      nombre: _nombre.text,
      email: _email.text,
      password: _password.text,
      telefono: _telefono.text,
    );

    // Si salió bien, la sesión ya está iniciada: cerramos esta pantalla
    // y debajo ya aparece el inicio.
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formulario,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Regístrate para entrar a cualquier gimnasio afiliado con una sola suscripción.',
                  style: textos.bodyMedium?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Escribe tu nombre'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) {
                      return 'Escribe tu correo';
                    }
                    if (!t.contains('@') || !t.contains('.')) {
                      return 'Escribe un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null; // es opcional
                    if (!RegExp(r'^\d{10}$').hasMatch(t)) {
                      return 'Debe tener 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _password,
                  obscureText: _ocultarPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmar,
                  obscureText: _ocultarConfirmar,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) =>
                      auth.cargando ? null : _registrarme(),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarConfirmar
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _ocultarConfirmar = !_ocultarConfirmar,
                      ),
                    ),
                  ),
                  validator: (v) => v != _password.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: 16),

                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x14DC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(color: AppColors.rojo),
                    ),
                  ),
                const SizedBox(height: 16),

                FilledButton(
                  onPressed: auth.cargando ? null : _registrarme,
                  child: auth.cargando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
