import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  Future<List<dynamic>>? _futureHistorial;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cargar historial solo una vez cuando tengamos acceso al AuthProvider
    _futureHistorial ??= _loadHistorial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadHistorial() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    final clienteId = auth.user?.clienteId ?? 0;
    if (clienteId == 0) {
      return [];
    }

    try {
      final data = await cart.getHistorial(clienteId);
      return data;
    } catch (e) {
      debugPrint('Error obteniendo historial: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis compras'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buscador
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(20, 0, 0, 0),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar compra',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF4B4B4B),
                        ),
                        prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF4B4B4B)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtros visuales (no funcionales por ahora)
                  Row(
                    children: [
                      Expanded(
                        child: _FilterChipLike(
                          label: 'Categoría',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterChipLike(
                          label: 'Fecha',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureHistorial,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar historial: ${snapshot.error}'),
                    );
                  }

                  final compras = snapshot.data ?? [];

                  if (compras.isEmpty) {
                    return const Center(
                      child: Text('Aún no tienes compras registradas.'),
                    );
                  }

                  // Filtro simple por texto (folio, fecha, estado)
                  final filtered = compras.where((p) {
                    if (_searchQuery.isEmpty) return true;

                    String folio = '';
                    String status = '';
                    String date = '';

                    if (p is Map) {
                      final map = Map<String, dynamic>.from(p as Map);
                      folio = (map['folio'] ?? map['Folio'] ?? map['FOLIO'] ?? map['ventaId'] ?? map['VentaId'] ?? map['VENTAID'] ?? map['id'] ?? '').toString();
                      status = (map['estatus'] ?? map['Estatus'] ?? map['ESTATUS'] ?? map['status'] ?? map['STATUS'] ?? '').toString();
                      date = (map['fecha'] ?? map['Fecha'] ?? map['FECHA'] ?? map['date'] ?? '').toString();
                    } else {
                      folio = p.toString();
                    }

                    final q = _searchQuery.toLowerCase();
                    return folio.toLowerCase().contains(q) ||
                        status.toLowerCase().contains(q) ||
                        date.toLowerCase().contains(q);
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = filtered[index];

                      String folio = '';
                      String status = '';
                      String date = '';
                      String total = '';
                      int? primerArticuloId;

                      if (p is Map) {
                        final map = Map<String, dynamic>.from(p as Map);
                        // Debug: inspeccionar estructura real que llega del backend
                        debugPrint('Compra[$index]: $map');

                        folio = (map['folio'] ?? map['Folio'] ?? map['FOLIO'] ?? map['ventaId'] ?? map['VentaId'] ?? map['VENTAID'] ?? map['id'] ?? '').toString();
                        status = (map['estatus'] ?? map['Estatus'] ?? map['ESTATUS'] ?? map['status'] ?? map['STATUS'] ?? '').toString();
                        date = (map['fecha'] ?? map['Fecha'] ?? map['FECHA'] ?? map['date'] ?? '').toString();

                        final rawPrimerArt = map['primerArticuloId'] ?? map['PrimerArticuloId'] ?? map['PRIMERARTICULOID'];
                        if (rawPrimerArt is int) {
                          primerArticuloId = rawPrimerArt;
                        } else if (rawPrimerArt != null) {
                          primerArticuloId = int.tryParse(rawPrimerArt.toString());
                        }

                        final totalValue = map['total'] ?? map['Total'] ?? map['TOTAL'] ?? map['importeTotal'] ?? map['importeNeto'] ?? map['monto'];

                        debugPrint('  totalValue= $totalValue  (type: ${totalValue.runtimeType})');

                        if (totalValue is num) {
                          total = '\$${totalValue.toStringAsFixed(2)}';
                        } else if (totalValue != null) {
                          total = totalValue.toString();
                        }
                      } else {
                        folio = p.toString();
                      }

                      // Construir URL de imagen del primer articulo, si existe
                      String? imageUrl;
                      if (primerArticuloId != null && primerArticuloId! > 0) {
                        // ApiService.baseUrl ya incluye '/api'
                        imageUrl = '${ApiService.baseUrl}/ImagenesArticulos/Articulo/$primerArticuloId';
                      }

                      return _PurchaseCard(
                        folio: folio,
                        status: status,
                        date: date,
                        total: total,
                        imageUrl: imageUrl,
                        onTap: () {
                          if (p is Map) {
                            final map = Map<String, dynamic>.from(p as Map);
                            debugPrint('Compra seleccionada: $map');
                            Navigator.pushNamed(
                              context,
                              '/purchase-detail',
                              arguments: {'venta': map},
                            );
                          } else {
                            debugPrint('Compra seleccionada (no Map): $p');
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipLike extends StatelessWidget {
  final String label;

  const _FilterChipLike({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black54),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final String folio;
  final String status;
  final String date;
  final String total;
  final VoidCallback onTap;
  final String? imageUrl;

  const _PurchaseCard({
    required this.folio,
    required this.status,
    required this.date,
    required this.total,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final headerDate = date.isEmpty ? '' : date;

    // Color del estado segun su valor
    final statusLower = status.toLowerCase();
    Color statusColor;
    if (statusLower.contains('en camino')) {
      statusColor = const Color(0xFF3887BE); // azul
    } else if (statusLower.contains('entregado')) {
      statusColor = const Color(0xFF2E7D32); // verde
    } else {
      statusColor = const Color(0xFF202020); // gris/negro
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerDate.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              headerDate,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B4B4B),
              ),
            ),
          ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(20, 0, 0, 0),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0E0E0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.shopping_bag_outlined,
                              size: 22,
                              color: Color(0xFF555555),
                            );
                          },
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          size: 22,
                          color: Color(0xFF555555),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.isEmpty ? 'Pedido' : status,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (folio.isNotEmpty)
                        Text(
                          'Pedido #$folio',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0xFF4B4B4B),
                          ),
                        ),
                      if (total.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            total,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  child: const Text(
                    'Volver a comprar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3887BE),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}