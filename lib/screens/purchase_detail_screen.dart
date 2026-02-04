import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';

class PurchaseDetailScreen extends StatefulWidget {
  const PurchaseDetailScreen({super.key});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  Future<List<dynamic>>? _futureDetalle;
  Map<String, dynamic>? _venta;
  int? _ventaId;
  int? _doctoveId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_futureDetalle == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      final venta = (args['venta'] as Map?)?.cast<String, dynamic>();

      if (venta == null) {
        _futureDetalle = Future.value([]);
        return;
      }

      _venta = venta;

      // Resolver ventaId intentando con varias claves y convirtiendo a int si viene como string
      final rawVentaId = venta['ventaId'] ?? venta['VentaId'] ?? venta['VENTAID'] ?? venta['id'];
      if (rawVentaId is int) {
        _ventaId = rawVentaId;
      } else if (rawVentaId != null) {
        _ventaId = int.tryParse(rawVentaId.toString());
      }

      // Resolver DoctoveId si viene en la respuesta
      final rawDoctoveId = venta['doctoveId'] ?? venta['DoctoveId'] ?? venta['DOCTOVEID'];
      if (rawDoctoveId is int) {
        _doctoveId = rawDoctoveId;
      } else if (rawDoctoveId != null) {
        _doctoveId = int.tryParse(rawDoctoveId.toString());
      }

      if (_ventaId != null) {
        _futureDetalle = _loadDetalle(_ventaId!);
      } else {
        _futureDetalle = Future.value([]);
      }
    }
  }

  Future<List<dynamic>> _loadDetalle(int ventaId) async {
    final cart = context.read<CartProvider>();
    return await cart.getDetalleVenta(ventaId);
  }

  void _recomprar(List<dynamic> items) {
    final cart = context.read<CartProvider>();

    // Limpiar carrito actual
    cart.clear();

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final id = item['articuloId'] ?? item['ArticuloId'] ?? item['ARTICULOID'];
      final nombre = item['nombre'] ?? item['Nombre'] ?? item['NOMBRE'] ?? 'Artículo';
      final precioUnitario = item['precioUnitario'] ?? item['PrecioUnitario'] ?? item['PRECIOUNITARIO'] ?? 0;
      final cantidad = item['cantidad'] ?? item['Cantidad'] ?? item['CANTIDAD'] ?? 1;

      if (id == null) continue;

      final product = Product(
        id: id is int ? id : int.tryParse(id.toString()) ?? 0,
        name: nombre.toString(),
        price: (precioUnitario is num) ? precioUnitario.toDouble() : 0.0,
        stock: 1,
        lineaArticuloId: null,
      );

      final qty = (cantidad is num) ? cantidad.toInt() : 1;
      cart.addToCart(product, quantity: qty);
    }

    Navigator.pushNamed(context, '/cart');
  }

  @override
  Widget build(BuildContext context) {
    final folio = _venta != null ? (_venta!['folio'] ?? _venta!['FOLIO'] ?? _venta!['id'] ?? '').toString() : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(folio.isEmpty ? 'Detalle de compra' : 'Compra $folio'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureDetalle,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar detalle: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('No se encontraron artículos para esta compra.'),
            );
          }

          return Column(
            children: [
              if (_ventaId != null || _doctoveId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      [
                        if (_ventaId != null) 'Venta ID: $_ventaId',
                        if (_doctoveId != null) 'Doc: $_doctoveId',
                      ].join('  ·  '),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is! Map<String, dynamic>) {
                      return const SizedBox.shrink();
                    }

                    // Debug: inspeccionar estructura real de cada renglón de detalle
                    debugPrint('Detalle item[$index]: $item');

                    final nombre = (item['nombre'] ?? item['Nombre'] ?? item['NOMBRE'] ?? 'Artículo').toString();
                    final cantidad = item['cantidad'] ?? item['Cantidad'] ?? item['CANTIDAD'] ?? 1;
                    final precioUnitario = item['precioUnitario'] ?? item['PrecioUnitario'] ?? item['PRECIOUNITARIO'] ?? 0;
                    final total = item['total'] ?? item['Total'] ?? item['TOTAL'] ?? 0;

                    final qty = (cantidad is num) ? cantidad.toInt() : 1;
                    final precio = (precioUnitario is num) ? precioUnitario.toDouble() : 0.0;
                    final totalNum = (total is num) ? total.toDouble() : (precio * qty);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(nombre),
                        subtitle: Text('Cantidad: $qty  ·  Precio: \$${precio.toStringAsFixed(2)}'),
                        trailing: Text('\$${totalNum.toStringAsFixed(2)}'),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_ventaId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No se encontró el identificador de la venta para seguimiento.'),
                                ),
                              );
                              return;
                            }

                            final auth = context.read<AuthProvider>();

                            auth.apiService.dio
                                .get('/Seguimiento/envios/por-venta/${_ventaId!}')
                                .then((response) {
                              final data = response.data;
                              if (data is Map<String, dynamic>) {
                                final envioId = data['envioId'] ?? data['EnvioId'] ?? data['ENVIOID'];
                                if (envioId != null) {
                                  Navigator.pushNamed(
                                    context,
                                    '/tracking-detail',
                                    arguments: {'envioId': envioId},
                                  );
                                  return;
                                }
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'No se encontró un envío asociado a esta compra.'),
                                ),
                              );
                            }).catchError((e) {
                              debugPrint('Error obteniendo envío por venta: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Error al consultar el seguimiento de esta compra.'),
                                ),
                              );
                            });
                          },
                          child: const Text('Seguir pedido'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            final data = snapshot.data ?? [];
                            _recomprar(data);
                          },
                          child: const Text('Volver a comprar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
