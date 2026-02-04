import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/address.dart';

class AddressBookService {
  static const _addressesKey = 'addresses';
  static const _defaultAddressIdKey = 'default_address_id';

  Future<List<Address>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((m) => Address.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> saveAddresses(List<Address> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(addresses.map((a) => a.toJson()).toList());
    await prefs.setString(_addressesKey, raw);
  }

  Future<String?> getDefaultAddressId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultAddressIdKey);
  }

  Future<void> setDefaultAddressId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultAddressIdKey, id);
  }
}
