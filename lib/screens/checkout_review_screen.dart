import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'openpay_tokenize_screen.dart';
import 'openpay_spei_screen.dart';

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

  String _metodoPago = 'tarjeta';

  int? _pendingCotizacionId;
  String? _pendingDestino;

  Future<Map<String, dynamic>> _esperarResultadoPagoOpenpay(
    AuthProvider auth,
    int cotizacionId, {
    int maxSeconds = 600,
  }) async {
    final start = DateTime.now();
    while (mounted) {
      final elapsed = DateTime.now().difference(start).inSeconds;
      if (elapsed > maxSeconds) {
        throw Exception('Tiempo de espera agotado confirmando el pago.');
      }

      final resp = await auth.apiService.dio.get(
        '/carrito-checkout/pagos/openpay/resultado/$cotizacionId',
      );

      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        final data = resp.data as Map<String, dynamic>;
        final status = (data['status'] ?? data['Status'] ?? '')
            .toString()
            .toLowerCase();
        final conversion = data['conversion'] ?? data['Conversion'];
        if ((status == 'completed' || status == 'paid' || status == 'success') &&
            conversion != null) {
          return data;
        }
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw Exception('Checkout cancelado.');
  }

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
    final soportaWebViewToken = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

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
                  const SizedBox(height: 16),
                  const Text(
                    'Método de pago',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tarjeta'),
                    value: 'tarjeta',
                    groupValue: _metodoPago,
                    onChanged: (v) {
                      if (!soportaWebViewToken) return;
                      if (v == null) return;
                      setState(() {
                        _metodoPago = v;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('SPEI'),
                    value: 'spei',
                    groupValue: _metodoPago,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _metodoPago = v;
                      });
                    },
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
                            }
                          }

                          final int cotizacionId;
                          if (_pendingCotizacionId != null && _pendingDestino == destino) {
                            cotizacionId = _pendingCotizacionId!;
                          } else {
                            final cotStart = await context
                                .read<CartProvider>()
                                .crearCotizacionParaPago(
                                  clienteId,
                                  destino: destino,
                                  usuario: auth.user?.username,
                                );

                            final cotizacion =
                                (cotStart['cotizacion'] ?? {}) as Map<String, dynamic>;
                            final rawCotId =
                                cotizacion['doctoVeId'] ?? cotizacion['DoctoVeId'] ?? 0;
                            final parsedId = rawCotId is int
                                ? rawCotId
                                : int.tryParse(rawCotId.toString()) ?? 0;
                            if (parsedId <= 0) {
                              throw Exception('No se pudo obtener CotizacionId.');
                            }

                            _pendingCotizacionId = parsedId;
                            _pendingDestino = destino;
                            cotizacionId = parsedId;
                          }

                          if (_metodoPago == 'tarjeta') {
                            if (!soportaWebViewToken) {
                              throw Exception(
                                  'Pago con tarjeta requiere Android/iOS. En Windows usa SPEI o ejecuta en emulador/dispositivo.');
                            }
                            final cfgResp = await auth.apiService.dio.get(
                              '/carrito-checkout/pagos/openpay/config',
                            );

                            if (cfgResp.statusCode != 200 ||
                                cfgResp.data is! Map<String, dynamic>) {
                              throw Exception(
                                  'No se pudo obtener configuración pública de Openpay.');
                            }

                            final cfg = cfgResp.data as Map<String, dynamic>;
                            final merchantId =
                                (cfg['merchantId'] ?? cfg['MerchantId'] ?? '')
                                    .toString()
                                    .trim();
                            final publicKey =
                                (cfg['publicKey'] ?? cfg['PublicKey'] ?? '')
                                    .toString()
                                    .trim();
                            if (merchantId.isEmpty || publicKey.isEmpty) {
                              throw Exception(
                                  'Openpay no está configurado en el backend (MerchantId/PublicKey).');
                            }

                            FocusManager.instance.primaryFocus?.unfocus();
                            await Future<void>.delayed(const Duration(milliseconds: 120));

                            final result = await navigator.push<OpenpayTokenizeResult>(
                              MaterialPageRoute(
                                builder: (_) => OpenpayTokenizeScreen(
                                  merchantId: merchantId,
                                  publicKey: publicKey,
                                ),
                              ),
                            );

                            if (result == null) {
                              throw Exception('Tokenización cancelada.');
                            }

                            await auth.apiService.dio.post(
                              '/carrito-checkout/pagos/openpay/cargo/tarjeta',
                              data: {
                                'cotizacionId': cotizacionId,
                                'destino': destino,
                                'tokenId': result.tokenId,
                                'deviceSessionId': result.deviceSessionId,
                                'customerEmail': _correoController.text.trim(),
                              },
                            );

                            final resultado = await _esperarResultadoPagoOpenpay(
                              auth,
                              cotizacionId,
                              maxSeconds: 600,
                            );

                            final conversion = (resultado['conversion'] ??
                                resultado['Conversion']) as Map<String, dynamic>?;
                            if (conversion == null) {
                              throw Exception('Pago aprobado sin conversión.');
                            }

                            final docId = conversion['documentoGeneradoId'] ??
                                conversion['DocumentoGeneradoId'];
                            int? ventaId;
                            if (docId is int) {
                              ventaId = docId;
                            } else if (docId != null) {
                              ventaId = int.tryParse(docId.toString());
                            }

                            if (widget.deliveryType == 'domicilio') {
                              try {
                                await _crearEnvioSeguimiento(clienteId, auth,
                                    ventaId: ventaId);
                              } catch (e) {
                                debugPrint('Error creando envío en Seguimiento: $e');
                              }
                            }

                            if (!mounted) return;
                            navigator.pushNamed(
                              '/order-success',
                              arguments: {
                                'venta': conversion,
                                'total': cart.total,
                                'documentoId': ventaId,
                              },
                            );

                            // Flujo completado: ya no hay cotización pendiente.
                            _pendingCotizacionId = null;
                            _pendingDestino = null;
                          } else {
                            final speiResp = await auth.apiService.dio.post(
                              '/carrito-checkout/pagos/openpay/cargo/spei',
                              data: {
                                'cotizacionId': cotizacionId,
                                'destino': destino,
                                'customerEmail': _correoController.text.trim(),
                              },
                            );

                            if (speiResp.statusCode != 200 ||
                                speiResp.data is! Map<String, dynamic>) {
                              throw Exception(
                                  'Error iniciando SPEI: ${speiResp.data}');
                            }

                            final body = speiResp.data as Map<String, dynamic>;
                            final chargeId =
                                (body['chargeId'] ?? body['ChargeId'] ?? '')
                                    .toString();
                            final clabe =
                                (body['clabe'] ?? body['Clabe'])?.toString();
                            final agreement = (body['agreement'] ?? body['Agreement'])
                                ?.toString();
                            final paymentReference =
                                (body['paymentReference'] ?? body['PaymentReference'])
                                    ?.toString();

                            if (chargeId.trim().isEmpty) {
                              throw Exception('Openpay SPEI sin chargeId.');
                            }

                            await navigator.push(
                              MaterialPageRoute(
                                builder: (_) => OpenpaySpeiScreen(
                                  cotizacionId: cotizacionId,
                                  destino: destino,
                                  chargeId: chargeId,
                                  clabe: clabe,
                                  agreement: agreement,
                                  paymentReference: paymentReference,
                                ),
                              ),
                            );

                            // SPEI iniciado: dejamos la cotización como pendiente para consultar resultado.
                          }
                        } catch (e) {
                          if (mounted) {
                            var msg = e.toString();
                            if (e is DioException) {
                              final data = e.response?.data;
                              if (data is Map) {
                                final err = data['error'];
                                if (err != null) {
                                  msg = err.toString();
                                }
                              } else if (data != null) {
                                msg = data.toString();
                              } else if (e.message != null) {
                                msg = e.message!;
                              }
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $msg')),
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
