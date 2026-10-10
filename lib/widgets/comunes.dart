import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastillita de color con texto (categoría, nivel, etc.).
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;
  const Etiqueta({super.key, required this.texto, required this.fondo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Se muestra cuando un gimnasio no tiene foto o la foto no carga.
class SinFoto extends StatelessWidget {
  const SinFoto({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.naranjaClaro,
      child: const Center(
        child: Icon(Icons.fitness_center, size: 40, color: AppColors.naranja),
      ),
    );
  }
}

/// Tarjeta blanca con bordes redondeados.
class Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Tarjeta({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Compara el nivel del plan del socio con el que pide el gimnasio.
Widget etiquetaNivel(int nivelRequerido, int? nivelSocio) {
  if (nivelSocio == null) {
    return Etiqueta(
      texto: 'Nivel $nivelRequerido',
      fondo: const Color(0xFFF4F4F5),
      color: AppColors.textoSecundario,
    );
  }
  if (nivelSocio >= nivelRequerido) {
    return const Etiqueta(
      texto: '✓ Incluido en tu plan',
      fondo: Color(0x1F16A34A),
      color: AppColors.verde,
    );
  }
  return Etiqueta(
    texto: 'Requiere plan nivel $nivelRequerido',
    fondo: const Color(0x14DC2626),
    color: AppColors.rojo,
  );
}
