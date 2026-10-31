import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class EditarPerfilScreen extends StatefulWidget {
  final String? telefonoActual;
  const EditarPerfilScreen({super.key, this.telefonoActual});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  final _passwordActual = TextEditingController();
  late final String _emailOriginal;
  bool _guardando = false;
  bool _ocultar = true;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthProvider>().usuario;
    _nombre = TextEditingController(text: usuario?.nombre ?? '');
    _email = TextEditingController(text: usuario?.email ?? '');
    _emailOriginal = usuario?.email ?? '';
    _telefono = TextEditingController(text: widget.telefonoActual ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _email.dispose();
    _passwordActual.dispose();
    super.dispose();
  }

  bool get _cambiaCorreo =>
      _email.text.trim().toLowerCase() != _emailOriginal.toLowerCase();

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await context.read<AuthProvider>().actualizarPerfil(
            nombre: _nombre.text,
            telefono: _telefono.text,
            email: _email.text,
            passwordActual: _cambiaCorreo ? _passwordActual.text : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar datos')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe tu nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty || !t.contains('@')) return 'Escribe un correo válido';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            if (_cambiaCorreo) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordActual,
                obscureText: _ocultar,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  helperText: 'Para cambiar el correo necesitamos tu contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Escribe tu contraseña actual'
                    : null,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
