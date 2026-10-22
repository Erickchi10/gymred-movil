import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/acceso.dart';
import '../services/movil_service.dart';
import '../theme/app_theme.dart';

/// Escanea el QR de la entrada del gimnasio y muestra si se permite el paso.
class EscanearQrScreen extends StatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  State<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<EscanearQrScreen> {
  final _camara = MobileScannerController();
  bool _procesando = false;
  ResultadoAcceso? _resultado;

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  Future<void> _alDetectar(BarcodeCapture captura) async {
    // Ignora lecturas mientras se procesa una o mientras se muestra el resultado.
    if (_procesando || _resultado != null) return;

    final codigo =
        captura.barcodes.isEmpty ? null : captura.barcodes.first.rawValue;
    if (codigo == null || codigo.trim().isEmpty) return;

    setState(() {
      _procesando = true;
    });

    try {
      final resultado = await context.read<MovilService>().entrar(codigo);
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() {
        _procesando = false;
      });
    }
  }

  void _escanearOtra() {
    setState(() {
      _resultado = null;
      _procesando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: resultado != null
          ? _Resultado(
              resultado: resultado,
              onOtra: _escanearOtra,
              onListo: () => Navigator.of(context).pop(),
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: _camara,
                  onDetect: _alDetectar,
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 48,
                  child: Text(
                    'Apunta la cámara al QR de la entrada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
                if (_procesando)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.naranja),
                  ),
              ],
            ),
    );
  }
}

class _Resultado extends StatelessWidget {
  final ResultadoAcceso resultado;
  final VoidCallback onOtra;
  final VoidCallback onListo;

  const _Resultado({
    required this.resultado,
    required this.onOtra,
    required this.onListo,
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ok = resultado.permitido;
    final color = ok ? AppColors.verde : AppColors.rojo;
    final restantes = resultado.visitasRestantesHoy;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, size: 96, color: color),
          const SizedBox(height: 16),
          Text(
            ok ? '¡Bienvenido!' : 'Acceso denegado',
            textAlign: TextAlign.center,
            style: textos.headlineMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          if (resultado.motivo != null)
            Text(resultado.motivo!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (resultado.gimnasio != null) _Fila('Gimnasio', resultado.gimnasio!),
          if (resultado.plan != null) _Fila('Plan', resultado.plan!),
          if (ok && restantes != null)
            _Fila('Visitas que te quedan hoy', '$restantes'),
          const SizedBox(height: 32),
          FilledButton(onPressed: onListo, child: const Text('Listo')),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onOtra,
            child: const Text('Escanear otra vez'),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String titulo;
  final String valor;
  const _Fila(this.titulo, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo,
              style: const TextStyle(color: AppColors.textoSecundario)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
