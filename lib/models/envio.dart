class Envio {
  final int envioId;
  final int clienteId;
  final String? clienteNombre;
  final String? direccionLinea1;
  final String? direccionLinea2;
  final String? ciudad;
  final String? estado;
  final String? cp;
  final String? destinatarioNombre;
  final String? destinatarioTelefono;
  final double? destinoLatitud;
  final double? destinoLongitud;
  final int? transportistaId;
  final int? unidadId;
  final String estatus;
  final DateTime? fechaCreacion;
  final int? tiempoEstimadoMin;
  final String? notas;

  Envio({
    required this.envioId,
    required this.clienteId,
    required this.estatus,
    this.clienteNombre,
    this.direccionLinea1,
    this.direccionLinea2,
    this.ciudad,
    this.estado,
    this.cp,
    this.destinatarioNombre,
    this.destinatarioTelefono,
    this.destinoLatitud,
    this.destinoLongitud,
    this.transportistaId,
    this.unidadId,
    this.fechaCreacion,
    this.tiempoEstimadoMin,
    this.notas,
  });

  factory Envio.fromJson(Map<String, dynamic> json) {
    T? _get<T>(String a, String b) {
      final value = json[a] ?? json[b];
      if (value == null) return null;
      if (T == int) return (value is int ? value : int.tryParse(value.toString())) as T?;
      if (T == double) return (value is num ? value.toDouble() : double.tryParse(value.toString())) as T?;
      if (T == String) return value.toString() as T?;
      return value as T?;
    }

    final envioId = _get<int>('envioId', 'EnvioId') ?? 0;
    final clienteId = _get<int>('clienteId', 'ClienteId') ?? 0;

    DateTime? fechaCreacion;
    final fechaRaw = json['fechaCreacion'] ?? json['FechaCreacion'];
    if (fechaRaw is String && fechaRaw.isNotEmpty) {
      fechaCreacion = DateTime.tryParse(fechaRaw);
    }

    return Envio(
      envioId: envioId,
      clienteId: clienteId,
      estatus: _get<String>('estatus', 'Estatus') ?? '',
      clienteNombre: _get<String>('clienteNombre', 'ClienteNombre'),
      direccionLinea1: _get<String>('direccionLinea1', 'DireccionLinea1'),
      direccionLinea2: _get<String>('direccionLinea2', 'DireccionLinea2'),
      ciudad: _get<String>('ciudad', 'Ciudad'),
      estado: _get<String>('estado', 'Estado'),
      cp: _get<String>('cp', 'Cp'),
      destinatarioNombre: _get<String>('destinatarioNombre', 'DestinatarioNombre'),
      destinatarioTelefono: _get<String>('destinatarioTelefono', 'DestinatarioTelefono'),
      destinoLatitud: _get<double>('destinoLatitud', 'DestinoLatitud'),
      destinoLongitud: _get<double>('destinoLongitud', 'DestinoLongitud'),
      transportistaId: _get<int>('transportistaId', 'TransportistaId'),
      unidadId: _get<int>('unidadId', 'UnidadId'),
      fechaCreacion: fechaCreacion,
      tiempoEstimadoMin: _get<int>('tiempoEstimadoMin', 'TiempoEstimadoMin'),
      notas: _get<String>('notas', 'Notas'),
    );
  }
}
