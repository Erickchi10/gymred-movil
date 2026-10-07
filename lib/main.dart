import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GymredApp());
}

class GymredApp extends StatelessWidget {
  const GymredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gymred',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: Scaffold(
        appBar: AppBar(title: const Text('Gymred')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: AppColors.naranja),
              const SizedBox(height: 12),
              Text('Gymred', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FilledButton(onPressed: () {}, child: const Text('Botón de prueba')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
