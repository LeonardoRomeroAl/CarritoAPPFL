import 'package:flutter/material.dart';
import '../models/address.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({super.key});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
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
  int _index = -1;
  String _id = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    _id = args['id'] as String? ?? '';
    _streetController.text = args['street'] as String? ?? '';
    _postalCodeController.text = args['postalCode'] as String? ?? '';
    _stateController.text = args['state'] as String? ?? '';
    _cityController.text = args['city'] as String? ?? '';
    _localityController.text = args['locality'] as String? ?? '';
    _neighborhoodController.text = args['neighborhood'] as String? ?? '';
    _extNumberController.text = args['extNumber'] as String? ?? '';
    _intNumberController.text = args['intNumber'] as String? ?? '';
    _referencesController.text = args['references'] as String? ?? '';
    _contactNameController.text = args['contactName'] as String? ?? '';
    _phoneController.text = args['phone'] as String? ?? '';
    _noNumber = args['noNumber'] as bool? ?? false;
    _isResidential = args['isResidential'] as bool? ?? true;
    _isWork = args['isWork'] as bool? ?? false;
    _index = args['index'] as int? ?? -1;
  }

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
        title: const Text('Editar dirección'),
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
                  onPressed: () {
                    // Futuro: obtener ubicación actual
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi ubicación'),
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
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa la calle y número';
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
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el código postal';
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
                    if (v == null || v.trim().isEmpty) {
                      return 'Selecciona el estado';
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

                      final updated = Address(
                        id: _id.isNotEmpty
                            ? _id
                            : DateTime.now().millisecondsSinceEpoch.toString(),
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
                      );

                      Navigator.pop(context, {
                        'index': _index,
                        'address': updated,
                      });
                    },
                    child: const Text('Guardar cambios'),
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
