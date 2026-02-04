class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final int? lineaArticuloId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.lineaArticuloId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['articuloId'] ?? json['ARTICULO_ID'] ?? 0,
      name: json['descripcion'] ?? json['Descripcion'] ?? json['nombre'] ?? json['NOMBRE'] ?? 'Sin Nombre',
      price: _parsePrice(json),
      stock: _parseStock(json),
      lineaArticuloId: _parseLineaArticuloId(json),
    );
  }

  static double _parsePrice(Map<String, dynamic> json) {
    // Lista de posibles nombres que podría traer la API vieja/nueva
    final keys = ['precio', 'PRECIO', 'precioVenta', 'PRECIO_VENTA', 'price', 'Precio'];
    for (var key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return (json[key] as num).toDouble();
      }
    }
    return 0.0;
  }

  static int _parseStock(Map<String, dynamic> json) {
    final keys = ['existencia', 'EXISTENCIA', 'stock', 'existenciaVenta', 'EXISTENCIA_VENTA'];
    for (var key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return (json[key] as num).toInt();
      }
    }
    return 0;
  }

  static int? _parseLineaArticuloId(Map<String, dynamic> json) {
    final keys = ['lineaArticuloId', 'LineaArticuloId', 'LINEA_ARTICULO_ID'];
    for (var key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final v = json[key];
        if (v is int) return v;
        return int.tryParse(v.toString());
      }
    }
    return null;
  }
}
