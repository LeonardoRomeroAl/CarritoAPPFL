class LineaArticulo {
  final int id;
  final String name;
  final bool isHidden;

  LineaArticulo({
    required this.id,
    required this.name,
    required this.isHidden,
  });

  factory LineaArticulo.fromJson(Map<String, dynamic> json) {
    final idRaw = json['lineaArticuloId'] ?? json['LineaArticuloId'] ?? json['LINEA_ARTICULO_ID'] ?? json['id'];
    final nameRaw = json['nombre'] ?? json['Nombre'] ?? json['NOMBRE'] ?? json['name'] ?? '';
    final ocultoRaw = json['oculto'] ?? json['Oculto'] ?? json['OCULTO'] ?? json['hidden'];

    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    final name = nameRaw.toString();

    final oculto = (ocultoRaw ?? '').toString().toLowerCase();
    final isHidden = oculto == 's' || oculto == 'si' || oculto == '1' || oculto == 'true';

    return LineaArticulo(
      id: id,
      name: name,
      isHidden: isHidden,
    );
  }
}
