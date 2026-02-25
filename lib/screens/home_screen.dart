import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/linea_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  int? _selectedLineaArticuloId;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  int _selectedBottomIndex = 0; // 0: Inicio, 1: Favoritos, 2: Carrito, 3: Compras, 4: Perfil
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _cartButtonKey = GlobalKey();
  final GlobalKey _bottomFavoritesKey = GlobalKey();
  final Map<int, GlobalKey> _addButtonKeys = {};
  final Map<int, GlobalKey> _favoriteButtonKeys = {};

  GlobalKey _getAddButtonKey(int productId) {
    return _addButtonKeys.putIfAbsent(productId, () => GlobalKey());
  }

  GlobalKey _getFavoriteButtonKey(int productId) {
    return _favoriteButtonKeys.putIfAbsent(productId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<LineaProvider>().fetchLineas();
    });
  }

  void _playAddToCartAnimation(GlobalKey fromKey) {
    final overlay = Overlay.of(context);

    final fromContext = fromKey.currentContext;
    final toContext = _cartButtonKey.currentContext;
    if (fromContext == null || toContext == null) return;

    final fromBox = fromContext.findRenderObject() as RenderBox?;
    final toBox = toContext.findRenderObject() as RenderBox?;
    if (fromBox == null || toBox == null) return;

    final fromPos = fromBox.localToGlobal(Offset.zero);
    final toPos = toBox.localToGlobal(Offset.zero);

    final start = fromPos + Offset(fromBox.size.width * 0.5, fromBox.size.height * 0.5);
    final end = toPos + Offset(toBox.size.width * 0.5, toBox.size.height * 0.5);

    late final OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    final posAnim = Tween<Offset>(begin: start, end: end).animate(curve);
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 0.6), weight: 60),
    ]).animate(curve);
    final opacityAnim = Tween<double>(begin: 0.95, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final p = posAnim.value;
            return Positioned(
              left: p.dx - 12,
              top: p.dy - 12,
              child: Transform.scale(
                scale: scaleAnim.value,
                child: Opacity(
                  opacity: opacityAnim.value,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3887BE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(70, 0, 0, 0),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }

  void _playFavoriteToBottomFavoritesAnimation(GlobalKey fromKey) {
    final overlay = Overlay.of(context);

    final fromContext = fromKey.currentContext;
    final toContext = _bottomFavoritesKey.currentContext;
    if (fromContext == null || toContext == null) return;

    final fromBox = fromContext.findRenderObject() as RenderBox?;
    final toBox = toContext.findRenderObject() as RenderBox?;
    if (fromBox == null || toBox == null) return;

    final fromPos = fromBox.localToGlobal(Offset.zero);
    final toPos = toBox.localToGlobal(Offset.zero);

    final start = fromPos + Offset(fromBox.size.width * 0.5, fromBox.size.height * 0.5);
    final end = toPos + Offset(toBox.size.width * 0.5, toBox.size.height * 0.5);

    late final OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);
    final posAnim = Tween<Offset>(begin: start, end: end).animate(curve);
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.15), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 0.7), weight: 55),
    ]).animate(curve);
    final opacityAnim = Tween<double>(begin: 0.98, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );

    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final p = posAnim.value;
            return Positioned(
              left: p.dx - 12,
              top: p.dy - 12,
              child: Transform.scale(
                scale: scaleAnim.value,
                child: Opacity(
                  opacity: opacityAnim.value,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(70, 225, 29, 72),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.favorite, size: 14, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    controller.forward().whenComplete(() {
      entry.remove();
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productsProvider = context.watch<ProductProvider>();
    final lineasProvider = context.watch<LineaProvider>();
    final cart = context.watch<CartProvider>();
    final favorites = context.watch<FavoritesProvider>();

    final products = productsProvider.products;

    // Aplicar búsqueda local y filtro de favoritos en memoria
    List<Product> displayedProducts = products;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      displayedProducts = displayedProducts
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    }

    if (_showFavoritesOnly) {
      displayedProducts = displayedProducts
          .where((p) => favorites.isFavorite(p.id))
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      drawer: _SideMenu(
        onHomeTap: () {
          Navigator.pop(context);
          setState(() {
            _searchQuery = '';
            _showFavoritesOnly = false;
            _selectedCategoryIndex = 0;
            _selectedLineaArticuloId = null;
            _selectedBottomIndex = 0;
          });
        },
        onSearchTap: () {
          Navigator.pop(context);
          setState(() {
            _showFavoritesOnly = false;
          });
          _searchFocusNode.requestFocus();
        },
        onFavoritesTap: () {
          Navigator.pop(context);
          setState(() {
            _showFavoritesOnly = true;
            _selectedBottomIndex = 1;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, auth, cart),
            _buildBannerArea(context, lineasProvider),
            Expanded(
              child: productsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productsProvider.error != null
                      ? Center(child: Text('Error: ${productsProvider.error}'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                'Productos destacados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;

                                  int crossAxisCount;
                                  double childAspectRatio;
                                  if (w >= 900) {
                                    crossAxisCount = 5;
                                    childAspectRatio = 0.78;
                                  } else if (w >= 700) {
                                    crossAxisCount = 4;
                                    childAspectRatio = 0.72;
                                  } else if (w >= 500) {
                                    crossAxisCount = 3;
                                    childAspectRatio = 0.56;
                                  } else {
                                    crossAxisCount = 2;
                                    childAspectRatio = 0.72;
                                  }

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: childAspectRatio,
                                    ),
                                    itemCount: displayedProducts.length,
                                    itemBuilder: (ctx, i) {
                                      final prod = displayedProducts[i];
                                      final isFav = favorites.isFavorite(prod.id);
                                      final cartItemIndex = cart.items.indexWhere(
                                        (item) => item.product.id == prod.id,
                                      );
                                      final addButtonKey = _getAddButtonKey(prod.id);
                                      final favButtonKey = _getFavoriteButtonKey(prod.id);
                                      final quantityInCart = cartItemIndex >= 0
                                          ? cart.items[cartItemIndex].quantity
                                          : 0;
                                      return _ProductCard(
                                        product: prod,
                                        isFavorite: isFav,
                                        quantityInCart: quantityInCart,
                                        addButtonKey: addButtonKey,
                                        favoriteButtonKey: favButtonKey,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProductDetailScreen(product: prod),
                                            ),
                                          );
                                        },
                                        onToggleFavorite: () {
                                          final wasFav = favorites.isFavorite(prod.id);
                                          favorites.toggleFavorite(prod.id);
                                          if (!wasFav) {
                                            _playFavoriteToBottomFavoritesAnimation(favButtonKey);
                                          }
                                        },
                                        onAdd: () {
                                          if (prod.stock <= 0) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('"${prod.name}" no tiene existencias disponibles.'),
                                                behavior: SnackBarBehavior.floating,
                                                margin: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 16,
                                                  bottom: 80,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }

                                          _playAddToCartAnimation(addButtonKey);
                                          context.read<CartProvider>().addToCart(prod, quantity: 1);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, cart),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, CartProvider cart) {
    return Container(
      height: 82,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  isCollapsed: true,
                  hintText: 'Buscar...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.2,
                    letterSpacing: 0,
                    color: Color(0xFF4B4B4B),
                  ),
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
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.2,
                  letterSpacing: 0,
                  color: Color(0xFF4B4B4B),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(ctx).openDrawer();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineasTabs(BuildContext context, LineaProvider lineasProvider) {
    if (lineasProvider.isLoading) {
      return const SizedBox(
        height: 26,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    if (lineasProvider.error != null) {
      return SizedBox(
        height: 26,
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'No se pudieron cargar categorías',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<LineaProvider>().fetchLineas();
              },
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final lineas = lineasProvider.lineas.where((l) => !l.isHidden).toList();

    final tabsLabels = <String>['Inicio', ...lineas.map((l) => l.name)];
    final tabsIds = <int?>[null, ...lineas.map((l) => l.id)];

    if (_selectedCategoryIndex >= tabsLabels.length) {
      _selectedCategoryIndex = 0;
      _selectedLineaArticuloId = null;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabsLabels.length, (index) {
          final selected = index == _selectedCategoryIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                final selectedLineaId = tabsIds[index];
                setState(() {
                  _selectedCategoryIndex = index;
                  _selectedLineaArticuloId = selectedLineaId;
                  _showFavoritesOnly = false;
                });

                // Recargar productos filtrados por la línea seleccionada (o todos si es Inicio)
                context.read<ProductProvider>().fetchProducts(
                      lineaArticuloId: selectedLineaId,
                    );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabsLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 22,
                      height: 2,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBannerArea(BuildContext context, LineaProvider lineasProvider) {
    return Container(
      height: 218,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF111927),
            Color(0x001D3557),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Tabs de categorías
          Positioned(
            left: 16,
            right: 0,
            top: 8,
            child: _buildLineasTabs(context, lineasProvider),
          ),
          // Banner principal
          Positioned(
            left: 18,
            right: 18,
            top: 39,
            bottom: 18,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                image: const DecorationImage(
                  image: AssetImage('assets/banner_placeholder.png'),
                  fit: BoxFit.cover,
                  opacity: 0.9,
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Promociones especiales',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    final totalUnits = cart.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final hasItems = totalUnits > 0;

    return SizedBox(
      height: 78,
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
          // íconos
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Inicio
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedBottomIndex == 0)
                      Container(
                        width: 68,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    IconButton(
                      icon: Image.asset(
                        'assets/home1.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _showFavoritesOnly = false;
                          _selectedCategoryIndex = 0;
                          _selectedLineaArticuloId = null;
                          _selectedBottomIndex = 0;
                        });
                      },
                    ),
                  ],
                ),
                // Favoritos
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedBottomIndex == 1)
                      Container(
                        width: 68,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    IconButton(
                      key: _bottomFavoritesKey,
                      icon: Image.asset(
                        'assets/corazon.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        // No tenemos dos versiones del icono, por lo que solo usamos uno
                      ),
                      onPressed: () {
                        setState(() {
                          _showFavoritesOnly = !_showFavoritesOnly;
                          _selectedBottomIndex = _showFavoritesOnly ? 1 : 0;
                        });
                      },
                    ),
                  ],
                ),
                // botón central de carrito (ligeramente elevado para resaltar)
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                    child: Container(
                      key: _cartButtonKey,
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: hasItems ? const Color(0xFF3887BE) : const Color(0xFFE9EEF5),
                        borderRadius: BorderRadius.circular(18),
                        border: hasItems
                            ? null
                            : Border.all(
                                color: const Color(0xFFD2DAE6),
                                width: 1,
                              ),
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
                          Icon(
                            Icons.shopping_cart_outlined,
                            color: hasItems ? Colors.white : const Color(0xFF6B7280),
                            size: 28,
                          ),
                          if (hasItems)
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
                ),
                // Compras
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedBottomIndex == 3)
                      Container(
                        width: 68,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(3),
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
                        setState(() {
                          _selectedBottomIndex = 3;
                        });
                        Navigator.pushNamed(context, '/purchases');
                      },
                    ),
                  ],
                ),
                // Perfil
                Builder(
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedBottomIndex == 4)
                        Container(
                          width: 68,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      IconButton(
                        icon: Image.asset(
                          'assets/usuario.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedBottomIndex = 4;
                          });
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                    ],
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final int quantityInCart;
  final GlobalKey addButtonKey;
  final GlobalKey favoriteButtonKey;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.quantityInCart,
    required this.addButtonKey,
    required this.favoriteButtonKey,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(64, 12, 63, 129),
                blurRadius: 5.3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildProductImage(),
                        ),
                      ),
                    ),
                    if (quantityInCart > 0)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3887BE),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(60, 0, 0, 0),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$quantityInCart',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: AnimatedContainer(
                        key: favoriteButtonKey,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFavorite ? const Color(0xFFE11D48) : const Color(0xFF1E1E1E),
                            width: isFavorite ? 0 : 2,
                          ),
                          color: isFavorite ? const Color(0xFFE11D48) : Colors.white,
                          boxShadow: isFavorite
                              ? const [
                                  BoxShadow(
                                    color: Color.fromARGB(70, 225, 29, 72),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onToggleFavorite,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 1.0, end: isFavorite ? 1.18 : 1.0),
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: isFavorite ? Colors.white : const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        key: addButtonKey,
                        child: ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            backgroundColor: const Color(0xFF3887BE),
                            foregroundColor: const Color(0xFFF5F5F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          child: const Text('Agregar'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    // URL al endpoint de imagen del artículo
    final imageUrl = '${ApiService.baseUrl}/ImagenesArticulos/Articulo/${product.id}';

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Si no hay imagen o falla la carga, usamos el placeholder local
        return Image.asset(
          'assets/product_placeholder.png',
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _SideMenu extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFavoritesTap;

  const _SideMenu({
    required this.onHomeTap,
    required this.onSearchTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.username ?? 'Comprador';
    // El modelo User no expone correo, usamos un placeholder neutro
    const userEmail = 'comprador@email.com';

    return Drawer(
      width: 300,
      child: Container(
        color: const Color(0xFFF4F7FF),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF3887BE),
                      child: Text(
                        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'C',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202020),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _SideMenuItem(
                      icon: Icons.home_outlined,
                      label: 'Inicio',
                      onTap: () {
                        onHomeTap();
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.search,
                      label: 'Buscar',
                      onTap: () {
                        onSearchTap();
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.notifications_none,
                      label: 'Notificaciones',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.headset_mic_outlined,
                      label: 'Ayuda',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/help');
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Mis compras',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/purchases');
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.favorite_border,
                      label: 'Favoritos',
                      onTap: () {
                        onFavoritesTap();
                      },
                    ),
                    const Divider(height: 24, color: Color(0xFFE0E0E0)),
                    _SideMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Configuración',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile/settings');
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.description_outlined,
                      label: 'Términos y Condiciones',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/terms');
                      },
                    ),
                    _SideMenuItem(
                      icon: Icons.info_outline,
                      label: 'Acerca de LF Comercializadora',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/about');
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              _SideMenuItem(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(context);
                  auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF202020),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF202020),
        ),
      ),
      onTap: onTap,
    );
  }
}
