import 'package:flutter/material.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F7FF),
        title: const Text(
          'Elige la forma de entrega',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeliveryOptionCard(
              title: 'Enviar a domicilio',
              subtitle:
                  'Calle 1 123 - Colonia, Ciudad - CP 12345\nResidencial',
              primaryActionLabel: 'Modificar domicilio o elegir otro',
              onPrimaryAction: () {
                Navigator.pushNamed(context, '/address/select');
              },
              onTap: () {
                Navigator.pushNamed(context, '/address/select');
              },
            ),
            const SizedBox(height: 24),
            _DeliveryOptionCard(
              title: 'Recoger en almacén',
              subtitle:
                  'Almacén general\nCalle 1 123 - Colonia, Ciudad - CP 12345\nHorario: L - V 9:00 - 20:00 hrs',
              primaryActionLabel: 'Ver en el mapa',
              onPrimaryAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Abriría Google Maps con la ubicación'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/checkout-review',
                  arguments: {
                    'deliveryType': 'almacen',
                    'addressTitle': 'Almacén general',
                    'addressLine':
                        'Calle 1 123 - Colonia, Ciudad - CP 12345',
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onTap;

  const _DeliveryOptionCard({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onPrimaryAction,
                child: Text(primaryActionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
