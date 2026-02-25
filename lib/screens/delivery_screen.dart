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
        surfaceTintColor: const Color(0xFFF4F7FF),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFF202020)),
        ),
        titleSpacing: 0,
        title: const Text(
          'Elige la forma de entrega',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF202020),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeliveryOptionCard(
              leadingIcon: Icons.local_shipping_outlined,
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
              leadingIcon: Icons.store_mall_directory_outlined,
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
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onTap;

  const _DeliveryOptionCard({
    required this.leadingIcon,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6EAF2)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(25, 3, 43, 118),
              offset: Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE6EAF2)),
                    ),
                    child: Icon(
                      leadingIcon,
                      size: 20,
                      color: const Color(0xFF3887BE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202020),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Color(0xFF3887BE),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: Color(0xFF4B4B4B),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE6EAF2)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onPrimaryAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    foregroundColor: const Color(0xFF3887BE),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(primaryActionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
