import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/invoice_request.dart';

class InvoiceRequestService {
  static const _key = 'invoice_requests_v1';

  Future<List<InvoiceRequest>> getRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map(InvoiceRequest.fromJson)
        .toList();
  }

  Future<void> saveRequests(List<InvoiceRequest> requests) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(requests.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> addRequest(InvoiceRequest request) async {
    final list = await getRequests();
    final updated = [request, ...list];
    await saveRequests(updated);
  }
}
