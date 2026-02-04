import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/invoice_request.dart';
import '../services/invoice_request_service.dart';
import 'billing_form_screen.dart';
import 'invoice_request_form_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _loading = true;
  Map<String, dynamic>? _datos;
  bool _loadingRequests = true;
  List<InvoiceRequest> _requests = [];
  final _invoiceService = InvoiceRequestService();

  @override
  void initState() {
    super.initState();
    _load();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final list = await _invoiceService.getRequests();
    if (!mounted) return;
    setState(() {
      _requests = list;
      _loadingRequests = false;
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final clienteId = auth.user?.clienteId ?? 0;

    if (clienteId == 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _datos = null;
      });
      return;
    }

    try {
      final resp = await auth.apiService.dio.get(
        '/carrito-checkout/perfil/datos-fiscales/$clienteId',
      );

      if (!mounted) return;

      if (resp.statusCode == 200 && resp.data != null) {
        setState(() {
          _datos = Map<String, dynamic>.from(resp.data as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _datos = null;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _datos = null;
        _loading = false;
      });
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillingFormScreen(initial: _datos),
      ),
    );

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _openInvoiceRequestForm() async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InvoiceRequestFormScreen(),
      ),
    );

    if (saved == true) {
      await _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDatos = _datos != null && (_datos!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openForm,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Datos fiscales',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: _openForm,
                              child: Text(hasDatos ? 'Editar' : 'Agregar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!hasDatos)
                          const Text('Aún no tienes datos fiscales capturados.')
                        else ...[
                          _RowItem(label: 'Razón social', value: (_datos!['razonSocial'] ?? '').toString()),
                          const SizedBox(height: 6),
                          _RowItem(label: 'RFC', value: (_datos!['rfc'] ?? '').toString()),
                          const SizedBox(height: 6),
                          _RowItem(label: 'Uso CFDI', value: (_datos!['usoCfdi'] ?? '').toString()),
                          const SizedBox(height: 6),
                          _RowItem(label: 'Correo', value: (_datos!['email'] ?? '').toString()),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mis facturas',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: _openInvoiceRequestForm,
                              child: const Text('Solicitar factura'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_loadingRequests)
                          const Center(child: CircularProgressIndicator())
                        else if (_requests.isEmpty)
                          const Text('Aún no has solicitado facturas.')
                        else
                          Column(
                            children: _requests
                                .map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.receipt_long_outlined),
                                      title: Text(r.folio.isEmpty ? 'Solicitud' : r.folio),
                                      subtitle: Text('${r.email} · ${r.statusLabel}'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Pendiente: detalle/descarga PDF/XML cuando exista endpoint.')),
                                        );
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;

  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
