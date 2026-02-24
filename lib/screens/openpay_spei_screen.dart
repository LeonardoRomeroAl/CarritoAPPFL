import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class OpenpaySpeiScreen extends StatefulWidget {
  final int cotizacionId;
  final String destino;
  final String chargeId;
  final String? clabe;
  final String? agreement;
  final String? paymentReference;
  final int maxSeconds;

  const OpenpaySpeiScreen({
    super.key,
    required this.cotizacionId,
    required this.destino,
    required this.chargeId,
    this.clabe,
    this.agreement,
    this.paymentReference,
    this.maxSeconds = 900,
  });

  @override
  State<OpenpaySpeiScreen> createState() => _OpenpaySpeiScreenState();
}

class _OpenpaySpeiScreenState extends State<OpenpaySpeiScreen> {
  bool _checking = false;
  Timer? _timer;
  DateTime? _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _check(auto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check({required bool auto}) async {
    if (_checking) return;
    if (!mounted) return;

    final start = _start;
    if (start != null) {
      final elapsed = DateTime.now().difference(start).inSeconds;
      if (elapsed > widget.maxSeconds) {
        _timer?.cancel();
        if (!auto && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Tiempo de espera agotado. Si ya pagaste, intenta más tarde.'),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _checking = true;
    });

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    try {
      final resp = await auth.apiService.dio.get(
        '/carrito-checkout/pagos/openpay/resultado/${widget.cotizacionId}',
      );

      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        final data = resp.data as Map<String, dynamic>;
        final status = (data['status'] ?? data['Status'] ?? '')
            .toString()
            .toLowerCase();
        final conversion = data['conversion'] ?? data['Conversion'];
        if ((status == 'completed' || status == 'paid' || status == 'success') &&
            conversion != null) {
          _timer?.cancel();
          int? documentoId;
          if (conversion is Map) {
            final docId = conversion['documentoGeneradoId'] ??
                conversion['DocumentoGeneradoId'] ??
                conversion['ventaId'] ??
                conversion['VentaId'];
            if (docId is int) {
              documentoId = docId;
            } else if (docId != null) {
              documentoId = int.tryParse(docId.toString());
            }
          }
          navigator.pushNamed(
            '/order-success',
            arguments: {
              'venta': conversion,
              'documentoId': documentoId,
            },
          );
        } else {
          if (!auto && mounted) {
            final pretty = status.isEmpty ? 'pendiente' : status;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Estatus actual: $pretty')),
            );
          }
        }
      }
    } catch (e) {
      if (!auto && mounted) {
        var msg = e.toString();
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            final err = data['error'];
            if (err != null) {
              msg = err.toString();
            }
          } else if (data != null) {
            msg = data.toString();
          } else if (e.message != null) {
            msg = e.message!;
          }
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $msg')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Widget _row(String label, String? value) {
    final v = (value ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(v.isEmpty ? '-' : v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago SPEI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Realiza tu transferencia SPEI con estos datos:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _row('CLABE', widget.clabe),
            _row('Convenio', widget.agreement),
            _row('Referencia', widget.paymentReference),
            _row('Cargo', widget.chargeId),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checking ? null : () => _check(auto: false),
                child: _checking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ya pagué, verificar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
