class InvoiceRequest {
  final String id;
  final String folio;
  final String email;
  final String notes;
  final String status;
  final DateTime createdAt;

  const InvoiceRequest({
    required this.id,
    required this.folio,
    required this.email,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory InvoiceRequest.fromJson(Map<String, dynamic> json) {
    return InvoiceRequest(
      id: (json['id'] ?? '').toString(),
      folio: (json['folio'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'en_proceso').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folio': folio,
      'email': email,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'lista':
        return 'Lista';
      case 'en_proceso':
      default:
        return 'En proceso';
    }
  }
}
