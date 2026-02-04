import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class BillingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const BillingFormScreen({super.key, this.initial});

  @override
  State<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends State<BillingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _razonController = TextEditingController();
  final _rfcController = TextEditingController();
  final _usoCfdiController = TextEditingController();
  final _cpController = TextEditingController();
  final _correoController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? {};
    _razonController.text = (initial['razonSocial'] ?? '').toString();
    _rfcController.text = (initial['rfc'] ?? '').toString();
    _usoCfdiController.text = (initial['usoCfdi'] ?? '').toString();
    _cpController.text = (initial['codigoPostal'] ?? '').toString();
    _correoController.text = (initial['email'] ?? '').toString();
  }

  @override
  void dispose() {
    _razonController.dispose();
    _rfcController.dispose();
    _usoCfdiController.dispose();
    _cpController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final auth = context.read<AuthProvider>();
    final clienteId = auth.user?.clienteId ?? 0;

    if (clienteId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el cliente. Inicia sesión de nuevo.')),
        );
      }
      setState(() {
        _saving = false;
      });
      return;
    }

    try {
      final payload = {
        'clienteId': clienteId,
        'rfc': _rfcController.text.trim(),
        'razonSocial': _razonController.text.trim(),
        'codigoPostal': _cpController.text.trim(),
        'email': _correoController.text.trim(),
        'usoCfdi': _usoCfdiController.text.trim(),
      };

      final resp = await auth.apiService.dio.put(
        '/carrito-checkout/perfil/datos-fiscales',
        data: payload,
      );

      if (resp.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: ${resp.data}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
        title: const Text('Datos de facturación'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _razonController,
                  decoration: const InputDecoration(labelText: 'Razón social'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la razón social' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _rfcController,
                  decoration: const InputDecoration(labelText: 'RFC'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el RFC' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _usoCfdiController,
                  decoration: const InputDecoration(labelText: 'Uso de CFDI'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el uso de CFDI' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cpController,
                  decoration: const InputDecoration(labelText: 'Código Postal'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el código postal' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(labelText: 'Correo para factura'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el correo';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pendiente: subir CSF (PDF) y autollenado.')),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Subir CSF (opcional)'),
                  ),
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
                        : const Text('Guardar'),
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
