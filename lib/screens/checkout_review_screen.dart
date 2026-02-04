import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

class CheckoutReviewScreen extends StatefulWidget {
  final String deliveryType;
  final String addressTitle;
  final String addressLine;
  final double? lat;
  final double? lon;

  const CheckoutReviewScreen({
    super.key,
    required this.deliveryType,
    required this.addressTitle,
    required this.addressLine,
    this.lat,
    this.lon,
  });

  @override
  State<CheckoutReviewScreen> createState() => _CheckoutReviewScreenState();
}

class _CheckoutReviewScreenState extends State<CheckoutReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  final _razonController = TextEditingController();
  final _rfcController = TextEditingController();
  final _usoCfdiController = TextEditingController();
  final _correoController = TextEditingController();

  bool _isSubmitting = false;
  bool _showInvoiceForm = false;
  bool _requireInvoice = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos fiscales guardados del cliente al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDatosFiscales();
    });
  }

  @override
  void dispose() {
    _razonController.dispose();
    _rfcController.dispose();
    _usoCfdiController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _loadDatosFiscales() async {
    final auth = context.read<AuthProvider>();
    final clienteId = auth.user?.clienteId;

    if (clienteId == null || clienteId == 0) {
      return;
    }

    try {
      final response = await auth.apiService.dio
          .get('/carrito-checkout/perfil/datos-fiscales/$clienteId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        setState(() {
          _razonController.text = (data['razonSocial'] ?? '') as String;
          _rfcController.text = (data['rfc'] ?? '') as String;
          _usoCfdiController.text = (data['usoCfdi'] ?? '') as String;
          _correoController.text = (data['email'] ?? '') as String;

          // Si hay al menos un campo con valor, asumimos que normalmente requiere factura
          final hasAny = _razonController.text.isNotEmpty ||
              _rfcController.text.isNotEmpty ||
              _usoCfdiController.text.isNotEmpty ||
              _correoController.text.isNotEmpty;
          if (hasAny) {
            _requireInvoice = true;
            _showInvoiceForm = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos fiscales: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar y facturar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de productos
            const Text(
              'Resumen de compra',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  ...cart.items.map((item) => ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                            '${item.quantity} x \$${item.product.price.toStringAsFixed(2)}'),
                        trailing: Text(
                            '\$${(item.quantity * item.product.price).toStringAsFixed(2)}'),
                      )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${cart.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Datos de entrega
                  const Text(
                    'Entrega',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.deliveryType == 'domicilio'
                      ? 'Enviar a domicilio'
                      : 'Recoger en almacén'),
                  const SizedBox(height: 4),
                  Text(widget.addressTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(widget.addressLine),
                  const SizedBox(height: 24),
                  // Facturación
                  const Text(
                    'Datos de facturación',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Requiero factura'),
                    subtitle: const Text(
                        'Si se marca, la venta se genera como factura (F).'),
                    value: _requireInvoice,
                    onChanged: (value) {
                      setState(() {
                        _requireInvoice = value ?? false;
                        _showInvoiceForm = _requireInvoice;
                      });
                    },
                  ),
                  if (_showInvoiceForm)
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _razonController,
                            decoration: const InputDecoration(
                              labelText: 'Razón social',
                            ),
                            validator: (value) {
                              if (!_showInvoiceForm) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa la razón social';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _rfcController,
                            decoration: const InputDecoration(
                              labelText: 'RFC',
                            ),
                            validator: (value) {
                              if (!_showInvoiceForm) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el RFC';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usoCfdiController,
                            decoration: const InputDecoration(
                              labelText: 'Uso de CFDI',
                            ),
                            validator: (value) {
                              if (!_showInvoiceForm) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el uso de CFDI';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _correoController,
                            decoration: const InputDecoration(
                              labelText: 'Correo para factura',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (!_showInvoiceForm) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa el correo';
                              }
                              if (!value.contains('@')) {
                                return 'Correo no válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                // Futuro: seleccionar archivo CSF y leer datos
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Subir CSF (opcional)'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Bot f3n para volver directamente al carrito
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.settings.name == '/cart' ||
                        route.settings.name == '/home',
                  );
                },
                child: const Text('Volver al carrito'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_showInvoiceForm) {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                        }
                        setState(() {
                          _isSubmitting = true;
                        });

                        final auth = context.read<AuthProvider>();
                        final clienteId = auth.user?.clienteId ?? 0;

                        if (clienteId == 0) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No se encontró el cliente para la sesión actual. Vuelve a iniciar sesión.')),
                            );
                          }
                          setState(() {
                            _isSubmitting = false;
                          });
                          return;
                        }

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          final destino = _requireInvoice ? 'F' : 'R';

                          // Si requiere factura, guardamos/actualizamos los datos fiscales
                          if (_requireInvoice) {
                            try {
                              await auth.apiService.dio.put(
                                '/carrito-checkout/perfil/datos-fiscales',
                                data: {
                                  'clienteId': clienteId,
                                  'razonSocial': _razonController.text.trim(),
                                  'rfc': _rfcController.text.trim(),
                                  'usoCfdi': _usoCfdiController.text.trim(),
                                  'codigoPostal': '',
                                  'email': _correoController.text.trim(),
                                },
                              );
                            } catch (e) {
                              debugPrint('Error guardando datos fiscales: $e');
                              // No bloqueamos el flujo, pero informamos al usuario si se desea
                            }
                          }

                          final result = await context
                              .read<CartProvider>()
                              .checkoutSimulado(
                                clienteId,
                                destino: destino,
                                rfc: _requireInvoice
                                    ? _rfcController.text.trim()
                                    : null,
                                usoCfdi: _requireInvoice
                                    ? _usoCfdiController.text.trim()
                                    : null,
                              );

                          final ventaId = result['ventaId'] ?? result['VentaId'] ?? result['VENTAID'];

                          // Si la entrega es a domicilio, creamos un envío en el API de Seguimiento
                          if (widget.deliveryType == 'domicilio') {
                            try {
                              final rawVentaId =
                                  result['ventaId'] ?? result['VentaId'] ?? result['VENTAID'];
                              int? ventaId;
                              if (rawVentaId is int) {
                                ventaId = rawVentaId;
                              } else if (rawVentaId != null) {
                                ventaId = int.tryParse(rawVentaId.toString());
                              }

                              await _crearEnvioSeguimiento(clienteId, auth, ventaId: ventaId);
                            } catch (e) {
                              debugPrint('Error creando envío en Seguimiento: $e');
                              // No bloqueamos el flujo de la venta si falla la creación del envío
                            }
                          }

                          if (mounted) {
                            navigator.pushNamed(
                              '/order-success',
                              arguments: result,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar y pagar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearEnvioSeguimiento(int clienteId, AuthProvider auth,
      {int? ventaId}) async {
    // Por ahora usamos los datos de dirección tal como se muestran en la pantalla.
    // Más adelante se pueden separar en calle/número/colonia/ciudad si el modelo lo permite.

    // Coordenadas de destino: si la dirección tiene lat/lon, las usamos;
    // de lo contrario, usamos la matriz como valor por defecto.
    const double defaultLat = 19.815817005074766;
    const double defaultLon = -90.5270677134919;

    final double destinoLatitud = widget.lat ?? defaultLat;
    final double destinoLongitud = widget.lon ?? defaultLon;

    final user = auth.user;

    final data = <String, dynamic>{
      'clienteId': clienteId,
      'doctoveId': ventaId,
      'direccionLinea1': widget.addressTitle,
      'direccionLinea2': widget.addressLine,
      'ciudad': '',
      'estado': '',
      'cp': '',
      'destinatarioNombre': user?.username ?? '',
      'destinatarioTelefono': '',
      'destinoLatitud': destinoLatitud,
      'destinoLongitud': destinoLongitud,
      'notas': 'Envío generado desde app carrito',
    };

    final dio = auth.apiService.dio;
    await dio.post('/Seguimiento/envios', data: data);
  }
}
