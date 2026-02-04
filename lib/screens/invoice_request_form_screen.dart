import 'package:flutter/material.dart';

import '../models/invoice_request.dart';
import '../services/invoice_request_service.dart';

class InvoiceRequestFormScreen extends StatefulWidget {
  const InvoiceRequestFormScreen({super.key});

  @override
  State<InvoiceRequestFormScreen> createState() => _InvoiceRequestFormScreenState();
}

class _InvoiceRequestFormScreenState extends State<InvoiceRequestFormScreen> {
  final _service = InvoiceRequestService();
  final _formKey = GlobalKey<FormState>();

  final _folioController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _folioController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final now = DateTime.now();
      final req = InvoiceRequest(
        id: now.millisecondsSinceEpoch.toString(),
        folio: _folioController.text.trim(),
        email: _emailController.text.trim(),
        notes: _notesController.text.trim(),
        status: 'en_proceso',
        createdAt: now,
      );

      await _service.addRequest(req);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando solicitud: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar factura'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _folioController,
                  decoration: const InputDecoration(
                    labelText: 'Folio / Pedido / Remisión',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa el folio o número de pedido'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo para recibir la factura',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el correo';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios (opcional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar solicitud'),
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
