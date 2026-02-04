import 'package:flutter/material.dart';
import '../models/address.dart';
import '../services/address_book_service.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final _service = AddressBookService();

  bool _loading = true;
  List<Address> _addresses = [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final addrs = await _service.getAddresses();
    final defId = await _service.getDefaultAddressId();

    if (!mounted) return;
    setState(() {
      _addresses = addrs;
      _selectedId = (defId != null && defId.isNotEmpty)
          ? defId
          : (addrs.isNotEmpty ? addrs.first.id : null);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _service.saveAddresses(_addresses);
    if (_selectedId != null && _selectedId!.isNotEmpty) {
      await _service.setDefaultAddressId(_selectedId!);
    }
  }

  int _selectedIndex() {
    if (_selectedId == null || _selectedId!.isEmpty) return 0;
    final i = _addresses.indexWhere((a) => a.id == _selectedId);
    return i >= 0 ? i : 0;
  }

  Future<void> _add() async {
    final result = await Navigator.pushNamed(context, '/address/new');
    if (result is Address) {
      setState(() {
        _addresses = [..._addresses, result];
        _selectedId = result.id;
      });
      await _persist();
    }
  }

  Future<void> _edit(Address addr, int index) async {
    final result = await Navigator.pushNamed(
      context,
      '/address/edit',
      arguments: {
        'id': addr.id,
        'street': addr.street,
        'postalCode': addr.postalCode,
        'state': addr.state,
        'city': addr.city,
        'locality': addr.locality,
        'neighborhood': addr.neighborhood,
        'extNumber': addr.extNumber,
        'intNumber': addr.intNumber,
        'references': addr.references,
        'contactName': addr.contactName,
        'phone': addr.phone,
        'noNumber': addr.noNumber,
        'isResidential': addr.isResidential,
        'isWork': addr.isWork,
        'index': index,
      },
    );

    if (result is Map && result['index'] is int && result['address'] is Address) {
      final i = result['index'] as int;
      final updated = result['address'] as Address;
      if (i >= 0 && i < _addresses.length) {
        setState(() {
          _addresses = [..._addresses]..[i] = updated;
          if (_selectedId == addr.id) {
            _selectedId = updated.id;
          }
        });
        await _persist();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir una de tus direcciones'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _addresses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Aún no tienes direcciones guardadas.'),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _add,
                                  child: const Text('Agregar dirección'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _addresses.length,
                            itemBuilder: (context, index) {
                              final addr = _addresses[index];
                              final selectedIndex = _selectedIndex();
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: RadioGroup<int>(
                                  groupValue: selectedIndex,
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedId = _addresses[value].id;
                                    });
                                    await _persist();
                                  },
                                  child: RadioListTile<int>(
                                    value: index,
                                    title: Text(addr.shortTitle),
                                    subtitle: Text(addr.shortLine),
                                    secondary: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        await _edit(addr, index);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _add,
                        child: const Text('Agregar dirección'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addresses.isEmpty
                          ? null
                          : () {
                              final idx = _selectedIndex();
                              final addr = _addresses[idx];

                              Navigator.pushNamed(
                                context,
                                '/checkout-review',
                                arguments: {
                                  'deliveryType': 'domicilio',
                                  'addressTitle': addr.shortTitle,
                                  'addressLine': addr.shortLine,
                                  'lat': addr.lat,
                                  'lon': addr.lon,
                                },
                              );
                            },
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
