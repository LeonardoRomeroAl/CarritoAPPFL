import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? result;

    if (args is Map<String, dynamic>) {
      result = args;
    }

    // Nuevo flujo: la venta viene directamente del endpoint AdminPanel/Ventas
    final venta = (result?['venta'] ?? result ?? {}) as Map<String, dynamic>;

    final folioDoc = venta['folio']?.toString() ?? venta['Folio']?.toString() ?? '--';
    final tipoDoc = venta['tipo']?.toString() ?? venta['Tipo']?.toString() ?? '';
    final pedidoFolio = venta['pedidoFolio']?.toString() ?? '';

    final total = venta['total'] ?? venta['Total'] ?? venta['importeNeto'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra exitosa'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              '¡Gracias por tu compra!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Documento: $folioDoc${tipoDoc.isNotEmpty ? ' ($tipoDoc)' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
            if (pedidoFolio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Pedido: $pedidoFolio', style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 4),
            Text(
              'Total: \$${total.toString()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
