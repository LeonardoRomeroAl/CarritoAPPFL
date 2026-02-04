class Address {
  final String id;
  final String street;
  final String postalCode;
  final String state;
  final String city;
  final String locality;
  final String neighborhood;
  final String extNumber;
  final String intNumber;
  final String references;
  final String contactName;
  final String phone;
  final bool noNumber;
  final bool isResidential;
  final bool isWork;

  // Coordenadas opcionales de la ubicación seleccionada en mapa
  final double? lat;
  final double? lon;

  const Address({
    required this.id,
    required this.street,
    required this.postalCode,
    required this.state,
    required this.city,
    required this.locality,
    required this.neighborhood,
    required this.extNumber,
    required this.intNumber,
    required this.references,
    required this.contactName,
    required this.phone,
    required this.noNumber,
    required this.isResidential,
    required this.isWork,
    this.lat,
    this.lon,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: (json['id'] ?? '').toString(),
      street: (json['street'] ?? '').toString(),
      postalCode: (json['postalCode'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      locality: (json['locality'] ?? '').toString(),
      neighborhood: (json['neighborhood'] ?? '').toString(),
      extNumber: (json['extNumber'] ?? '').toString(),
      intNumber: (json['intNumber'] ?? '').toString(),
      references: (json['references'] ?? '').toString(),
      contactName: (json['contactName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      noNumber: (json['noNumber'] ?? false) == true,
      isResidential: (json['isResidential'] ?? true) == true,
      isWork: (json['isWork'] ?? false) == true,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street': street,
      'postalCode': postalCode,
      'state': state,
      'city': city,
      'locality': locality,
      'neighborhood': neighborhood,
      'extNumber': extNumber,
      'intNumber': intNumber,
      'references': references,
      'contactName': contactName,
      'phone': phone,
      'noNumber': noNumber,
      'isResidential': isResidential,
      'isWork': isWork,
      'lat': lat,
      'lon': lon,
    };
  }

  String get shortTitle => 'CP $postalCode';

  String get shortLine {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city.isNotEmpty) parts.add(city);
    if (postalCode.isNotEmpty) parts.add('CP $postalCode');
    return parts.join(' - ');
  }

  Address copyWith({
    String? id,
    String? street,
    String? postalCode,
    String? state,
    String? city,
    String? locality,
    String? neighborhood,
    String? extNumber,
    String? intNumber,
    String? references,
    String? contactName,
    String? phone,
    bool? noNumber,
    bool? isResidential,
    bool? isWork,
    double? lat,
    double? lon,
  }) {
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      state: state ?? this.state,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      neighborhood: neighborhood ?? this.neighborhood,
      extNumber: extNumber ?? this.extNumber,
      intNumber: intNumber ?? this.intNumber,
      references: references ?? this.references,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      noNumber: noNumber ?? this.noNumber,
      isResidential: isResidential ?? this.isResidential,
      isWork: isWork ?? this.isWork,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}
