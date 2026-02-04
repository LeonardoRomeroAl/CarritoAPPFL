import 'package:flutter/material.dart';

import '../models/address.dart';
import '../services/address_book_service.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  final _service = AddressBookService();

  bool _loading = true;
  List<Address> _addresses = [];
  String? _defaultId;

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
      _defaultId = defId;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _service.saveAddresses(_addresses);
    if (_defaultId != null && _defaultId!.isNotEmpty) {
      await _service.setDefaultAddressId(_defaultId!);
    }
  }

  Future<void> _add() async {
    final result = await Navigator.pushNamed(context, '/address/new');
    if (result is Address) {
      setState(() {
        _addresses = [..._addresses, result];
        _defaultId ??= result.id;
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
          if (_defaultId == addr.id) {
            _defaultId = updated.id;
          }
        });
        await _persist();
      }
    }
  }

  Future<void> _delete(Address addr, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text('¿Seguro que deseas eliminar esta dirección?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _addresses = [..._addresses]..removeAt(index);
      if (_defaultId == addr.id) {
        _defaultId = _addresses.isNotEmpty ? _addresses.first.id : null;
      }
    });

    await _persist();
  }

  Future<void> _setDefault(Address addr) async {
    setState(() {
      _defaultId = addr.id;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis direcciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _add,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final addr = _addresses[index];
                    final isDefault = _defaultId != null && _defaultId == addr.id;

                    return Card(
                      child: ListTile(
                        title: Text(addr.shortTitle),
                        subtitle: Text(addr.shortLine),
                        leading: isDefault
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.location_on_outlined),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'default') {
                              await _setDefault(addr);
                            } else if (value == 'edit') {
                              await _edit(addr, index);
                            } else if (value == 'delete') {
                              await _delete(addr, index);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'default', child: Text('Marcar como principal')),
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                        onTap: () async {
                          await _setDefault(addr);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
