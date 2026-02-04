import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/address.dart';
import 'map_picker_screen.dart';

class NewAddressScreen extends StatefulWidget {
  const NewAddressScreen({super.key});

  @override
  State<NewAddressScreen> createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<NewAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _extNumberController = TextEditingController();
  final _intNumberController = TextEditingController();
  final _referencesController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _noNumber = false;
  bool _isResidential = true;
  bool _isWork = false;

  double? _lat;
  double? _lon;

  @override
  void dispose() {
    _streetController.dispose();
    _postalCodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    _neighborhoodController.dispose();
    _extNumberController.dispose();
    _intNumberController.dispose();
    _referencesController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva dirección'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    // Abrir mapa para elegir ubicación
                    const double defaultLat = 19.815817005074766;
                    const double defaultLon = -90.5270677134919;

                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapPickerScreen(
                          initialLat: defaultLat,
                          initialLon: defaultLon,
                        ),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _lat = result.latitude;
                        _lon = result.longitude;

                        // Autocompletar algunos campos de dirección si están vacíos,
                        // para que el usuario pueda continuar solo con la selección en mapa.
                        if (_streetController.text.trim().isEmpty) {
                          _streetController.text = 'Ubicación seleccionada en mapa';
                        }
                        if (_stateController.text.trim().isEmpty) {
                          _stateController.text = 'Campeche';
                        }
                        if (_postalCodeController.text.trim().isEmpty) {
                          _postalCodeController.text = '00000';
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.map),
                  label: Text(
                    _lat != null && _lon != null
                        ? 'Ubicación seleccionada en mapa'
                        : 'Elegir ubicación en mapa',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dirección o lugar de entrega',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Avenida las palmas 123',
                  ),
                  validator: (v) {
                    if (_lat == null || _lon == null) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa la calle y número';
                      }
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _noNumber,
                      onChanged: (value) {
                        setState(() {
                          _noNumber = value ?? false;
                        });
                      },
                    ),
                    const Text('Sin número'),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código Postal',
                    hintText: 'Ej: 12345',
                  ),
                  validator: (v) {
                    if (_lat == null || _lon == null) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el código postal';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                  ),
                  validator: (v) {
                    if (_lat == null || _lon == null) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Selecciona el estado';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Municipio o alcaldía',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _localityController,
                  decoration: const InputDecoration(
                    labelText: 'Localidad',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _neighborhoodController,
                  decoration: const InputDecoration(
                    labelText: 'Colonia o barrio',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _extNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número exterior (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _intNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número interior (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referencesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Indicaciones para la entrega (opcional)',
                    hintText:
                        'Ej: Entre calles, color del edificio, no tiene timbre...',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tipo de domicilio',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Residencial'),
                      selected: _isResidential,
                      onSelected: (value) {
                        setState(() {
                          _isResidential = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Laboral'),
                      selected: _isWork,
                      onSelected: (value) {
                        setState(() {
                          _isWork = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Datos de contacto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y apellido',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '123 123456',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      final address = Address(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        street: _streetController.text.trim(),
                        postalCode: _postalCodeController.text.trim(),
                        state: _stateController.text.trim(),
                        city: _cityController.text.trim(),
                        locality: _localityController.text.trim(),
                        neighborhood: _neighborhoodController.text.trim(),
                        extNumber: _extNumberController.text.trim(),
                        intNumber: _intNumberController.text.trim(),
                        references: _referencesController.text.trim(),
                        contactName: _contactNameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        noNumber: _noNumber,
                        isResidential: _isResidential,
                        isWork: _isWork,
                        lat: _lat,
                        lon: _lon,
                      );

                      Navigator.pop(context, address);
                    },
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
