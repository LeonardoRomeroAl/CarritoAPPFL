import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Necesitas ayuda?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Futuro: abrir chat o canal de soporte
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contactar soporte'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sigue tu compra',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa el estado de tus compras en la sección "Mis compras" del menú principal.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Más ayuda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Próximamente agregaremos preguntas frecuentes y guías rápidas.',
            ),
          ],
        ),
      ),
    );
  }
}
