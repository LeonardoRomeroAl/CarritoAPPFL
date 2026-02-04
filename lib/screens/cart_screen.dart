import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _selectAll = false;
  final Map<int, bool> _selectedByProductId = {};

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // Al entrar, seleccionar todos los productos por defecto
    if (cart.items.isNotEmpty && _selectedByProductId.isEmpty && !_selectAll) {
      _selectAll = true;
      for (final item in cart.items) {
        _selectedByProductId[item.product.id] = true;
      }
    }

    if (cart.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Carrito')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Carrito')),
        body: const Center(child: Text('El carrito está vacío')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Carrito')),
      body: Column(
        children: [
          // Seleccionar todo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      for (final item in cart.items) {
                        _selectedByProductId[item.product.id] = _selectAll;
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
                const Text('Seleccionar todo'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final item = cart.items[i];
                final product = item.product;
                final isSelected = _selectedByProductId[product.id] ?? _selectAll;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // checkbox
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  _selectedByProductId[product.id] = value ?? false;
                                  _selectAll = _selectedByProductId.values
                                          .isNotEmpty &&
                                      _selectedByProductId.values
                                          .every((v) => v);
                                });
                              },
                            ),
                            // imagen placeholder
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/product_placeholder.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // nombre y precio
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(Icons.favorite_border,
                                      size: 18, color: Colors.grey),
                                ],
                              ),
                            ),
                            // Borrar
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cart.removeItem(product.id);
                                  _selectedByProductId.remove(product.id);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Cantidad y total parcial
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DropdownButton<int>(
                              value: item.quantity,
                              items: List.generate(10, (index) => index + 1)
                                  .map((q) => DropdownMenuItem<int>(
                                        value: q,
                                        child: Text(q.toString()),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                cart.updateQuantity(product.id, value);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Total + botón continuar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(25, 3, 43, 118),
                  offset: Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${cart.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/delivery');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3887BE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Continuar compra'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
