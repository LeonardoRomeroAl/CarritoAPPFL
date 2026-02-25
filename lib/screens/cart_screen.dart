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
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

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
        backgroundColor: const Color(0xFFF4F7FF),
        body: Column(
          children: [
            _buildHeader(context),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        bottomNavigationBar: _buildBottomArea(context, cart, enabled: false),
      );
    }

    if (cart.items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FF),
        body: Column(
          children: [
            _buildHeader(context),
            const Expanded(child: Center(child: Text('El carrito está vacío'))),
          ],
        ),
        bottomNavigationBar: _buildBottomArea(context, cart, enabled: false),
      );
    }

    final displayedItems = _searchQuery.trim().isEmpty
        ? cart.items
        : cart.items
            .where(
              (i) => i.product.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()),
            )
            .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6EAF2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(25, 3, 43, 118),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _selectAll,
                      onChanged: (value) {
                        setState(() {
                          _selectAll = value ?? false;
                          for (final item in displayedItems) {
                            _selectedByProductId[item.product.id] = _selectAll;
                          }
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seleccionar todo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF202020),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 190),
              itemCount: displayedItems.length,
              itemBuilder: (ctx, i) {
                final item = displayedItems[i];
                final product = item.product;
                final isSelected = _selectedByProductId[product.id] ?? _selectAll;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE6EAF2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(25, 3, 43, 118),
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                _selectedByProductId[product.id] = value ?? false;
                                _selectAll = _selectedByProductId.values.isNotEmpty &&
                                    _selectedByProductId.values.every((v) => v);
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F7FF),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/product_placeholder.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF202020),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF202020),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                Icons.favorite,
                                size: 18,
                                color: Colors.red.withValues(alpha: 0.85),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cart.removeItem(product.id);
                                  _selectedByProductId.remove(product.id);
                                });
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE6EAF2)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: item.quantity,
                                  items: List.generate(10, (index) => index + 1)
                                      .map(
                                        (q) => DropdownMenuItem<int>(
                                          value: q,
                                          child: Text(
                                            q.toString(),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    cart.updateQuantity(product.id, value);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                  borderRadius: BorderRadius.circular(8),
                                  dropdownColor: Colors.white,
                                ),
                              ),
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
        ],
      ),
      bottomNavigationBar: _buildBottomArea(context, cart, enabled: displayedItems.isNotEmpty),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 82,
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111927),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Image.asset(
              'assets/logoamarillo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  isCollapsed: true,
                  hintText: 'Buscar...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: Opacity(
                      opacity: 0.75,
                      child: Image.asset(
                        'assets/icon.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  contentPadding: const EdgeInsets.only(top: 12, bottom: 12),
                ),
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: Color(0xFF202020),
                ),
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomArea(BuildContext context, CartProvider cart, {required bool enabled}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSummarySheet(context, cart, enabled: enabled),
        _buildBottomNavBar(context, cart),
      ],
    );
  }

  Widget _buildSummarySheet(BuildContext context, CartProvider cart, {required bool enabled}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202020),
                  ),
                ),
                Text(
                  '\$${cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202020),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: enabled
                    ? () {
                        Navigator.pushNamed(context, '/delivery');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3887BE),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8C7D9),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continuar compra',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, CartProvider cart) {
    final totalUnits = cart.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return SizedBox(
      height: 78 + MediaQuery.of(context).padding.bottom,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(25, 3, 43, 118),
                    offset: Offset(0, -5),
                    blurRadius: 9,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/home1.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/corazon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                  ),
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3887BE),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(80, 35, 80, 147),
                            blurRadius: 4,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                          if (totalUnits > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$totalUnits',
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/shopping.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/purchases');
                    },
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/usuario.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
