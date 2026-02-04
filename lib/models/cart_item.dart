class CartItem {
  final int id; // DOCTO_PV_DET_ID o API_CARRITO_DET_ID
  final int articuloId;
  final String productName;
  final double price;
  final double quantity;

  CartItem({
    required this.id,
    required this.articuloId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['apiCarritoDetId'] ?? 0,
      articuloId: json['articuloId'],
      productName: json['nombreArticulo'] ?? 'Artículo',
      price: (json['precioUnitario'] as num).toDouble(),
      quantity: (json['unidades'] as num).toDouble(),
    );
  }
}
