import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _Title(),
            SizedBox(height: 12),
            _Section(
              number: '1',
              title: 'Aceptación de los términos',
              body:
                  'Al descargar, registrarse o utilizar la aplicación móvil de LF Comercializadora, el usuario acepta expresamente los presentes Términos y Condiciones. Si no está de acuerdo, deberá abstenerse de utilizar la app.',
            ),
            _Section(
              number: '2',
              title: 'Uso de la aplicación',
              body:
                  'La app está destinada exclusivamente para la consulta, cotización y compra de materiales de construcción. El usuario se compromete a hacer un uso adecuado, lícito y conforme a la legislación vigente.',
            ),
            _Section(
              number: '3',
              title: 'Registro del usuario',
              body:
                  'Para realizar compras, el usuario deberá proporcionar información veraz, actualizada y completa. LF Comercializadora no se hace responsable por errores derivados de datos incorrectos proporcionados por el usuario.',
            ),
            _Section(
              number: '4',
              title: 'Disponibilidad de productos',
              body:
                  'La disponibilidad de los productos está sujeta a inventario. Las imágenes mostradas en la app son ilustrativas y pueden variar ligeramente del producto real.',
            ),
            _Section(
              number: '5',
              title: 'Precios',
              body:
                  'Los precios publicados están expresados en moneda nacional y pueden cambiar sin previo aviso. El precio final aplicable será el mostrado al momento de confirmar el pedido.',
            ),
            _Section(
              number: '6',
              title: 'Promociones y ofertas',
              body:
                  'Las promociones, descuentos y ofertas están sujetas a vigencia, disponibilidad y condiciones específicas. No son acumulables, salvo que se indique expresamente.',
            ),
            _Section(
              number: '7',
              title: 'Proceso de compra',
              body:
                  'Una vez confirmado el pedido y recibido el pago, LF Comercializadora procederá con la preparación y envío del mismo conforme a las condiciones establecidas.',
            ),
            _Section(
              number: '8',
              title: 'Formas de pago',
              body:
                  'La app acepta los métodos de pago habilitados dentro de la plataforma. LF Comercializadora no almacena información bancaria sensible del usuario.',
            ),
            _Section(
              number: '9',
              title: 'Facturación',
              body:
                  'El usuario podrá solicitar factura dentro del plazo indicado en la app. Es responsabilidad del usuario proporcionar correctamente sus datos fiscales.',
            ),
            _Section(
              number: '10',
              title: 'Entregas',
              body:
                  'Los tiempos de entrega son estimados y pueden variar por causas ajenas a LF Comercializadora, como tráfico, clima o disponibilidad logística.',
            ),
            _Section(
              number: '11',
              title: 'Recepción del pedido',
              body:
                  'El usuario deberá verificar los materiales al momento de la entrega. Cualquier aclaración deberá reportarse dentro de las 24 horas posteriores a la recepción.',
            ),
            _Section(
              number: '12',
              title: 'Cancelaciones',
              body:
                  'Las cancelaciones solo podrán realizarse antes de que el pedido haya sido enviado. Una vez despachado, no será posible cancelar.',
            ),
            _Section(
              number: '13',
              title: 'Devoluciones y reembolsos',
              body:
                  'Solo se aceptarán devoluciones por defectos de fábrica o errores en el pedido. El material deberá encontrarse sin uso y en su empaque original.',
            ),
            _Section(
              number: '14',
              title: 'Responsabilidad',
              body:
                  'LF Comercializadora no se hace responsable por daños derivados del uso indebido de los materiales adquiridos.',
            ),
            _Section(
              number: '15',
              title: 'Propiedad intelectual',
              body:
                  'Todo el contenido de la app, incluyendo logotipos, textos e imágenes, es propiedad de LF Comercializadora y está protegido por las leyes aplicables.',
            ),
            _Section(
              number: '16',
              title: 'Privacidad de datos',
              body:
                  'La información personal del usuario será tratada conforme a nuestro Aviso de Privacidad y a la legislación vigente en materia de protección de datos.',
            ),
            _Section(
              number: '17',
              title: 'Modificaciones',
              body:
                  'LF Comercializadora se reserva el derecho de modificar estos Términos y Condiciones en cualquier momento. Los cambios serán notificados a través de la app.',
            ),
            _Section(
              number: '18',
              title: 'Suspensión del servicio',
              body:
                  'LF Comercializadora podrá suspender temporal o definitivamente el acceso a la app por mantenimiento, causas técnicas o uso indebido.',
            ),
            _Section(
              number: '19',
              title: 'Legislación aplicable',
              body:
                  'Estos Términos y Condiciones se rigen por las leyes aplicables en los Estados Unidos Mexicanos.',
            ),
            _Section(
              number: '20',
              title: 'Contacto',
              body:
                  'Para cualquier duda o aclaración, el usuario podrá comunicarse a través de los canales de contacto disponibles dentro de la app.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Términos y Condiciones',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 2),
        Text(
          'LF Comercializadora',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Section({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(height: 1.35),
          ),
        ],
      ),
    );
  }
}
