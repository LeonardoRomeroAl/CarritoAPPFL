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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F7FF),
        surfaceTintColor: const Color(0xFFF4F7FF),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFF202020)),
        ),
        titleSpacing: 0,
        title: const Text(
          'Elegir una de tus direcciones',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF202020),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_addresses.isEmpty)
                      Center(
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
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE6EAF2)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(25, 3, 43, 118),
                              offset: Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _addresses.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (context, index) {
                                return const Divider(
                                  height: 1,
                                  color: Color(0xFFE6EAF2),
                                );
                              },
                              itemBuilder: (context, index) {
                                final addr = _addresses[index];
                                final isSelected = index == selectedIndex;

                                Future<void> selectThis() async {
                                  setState(() {
                                    _selectedId = addr.id;
                                  });
                                  await _persist();
                                }

                                return InkWell(
                                  onTap: selectThis,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF3887BE)
                                                : const Color(0xFFDCE6F5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                                              : const SizedBox.shrink(),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                addr.shortTitle,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF202020),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                addr.shortLine,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  height: 1.25,
                                                  color: Color(0xFF4B4B4B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFE6EAF2)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/profile/addresses');
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: const Color(0xFF3887BE),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Ver todas'),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/profile/addresses');
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: const Color(0xFF3887BE),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Editar direcciones'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3887BE),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFB8C7D9),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
