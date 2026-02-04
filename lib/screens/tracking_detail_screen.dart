import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/envio.dart';
import '../providers/auth_provider.dart';

class TrackingDetailScreen extends StatefulWidget {
  const TrackingDetailScreen({super.key});

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  Future<Envio?>? _futureEnvio;
  int? _envioId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureEnvio == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
      final id = args['envioId'];
      if (id is int) {
        _envioId = id;
        _futureEnvio = _loadEnvio(id);
      } else {
        _futureEnvio = Future.value(null);
      }
    }
  }

  Future<Envio?> _loadEnvio(int envioId) async {
    final auth = context.read<AuthProvider>();
    try {
      final dio = auth.apiService.dio;
      final response = await dio.get('/Seguimiento/envios/$envioId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Envio.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo detalle envío: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_envioId != null ? 'Envío #$_envioId' : 'Seguimiento'),
      ),
      body: FutureBuilder<Envio?>(
        future: _futureEnvio,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar envío: ${snapshot.error}'),
            );
          }

          final envio = snapshot.data;
          if (envio == null) {
            return const Center(child: Text('No se encontró información del envío.'));
          }

          final direccion = [
            envio.direccionLinea1 ?? '',
            envio.direccionLinea2 ?? '',
            envio.ciudad ?? '',
            envio.estado ?? '',
          ].where((x) => x.trim().isNotEmpty).join(', ');

          final fecha = envio.fechaCreacion != null
              ? '${envio.fechaCreacion!.day.toString().padLeft(2, '0')}/'
                  '${envio.fechaCreacion!.month.toString().padLeft(2, '0')}/'
                  '${envio.fechaCreacion!.year}'
              : '';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destino',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(direccion.isEmpty ? 'Envío #${envio.envioId}' : direccion),
                const SizedBox(height: 8),
                if (fecha.isNotEmpty)
                  Text('Creado el $fecha', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Text(
                  'Estatus actual',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(envio.estatus),
                ),
                const SizedBox(height: 16),
                if (envio.tiempoEstimadoMin != null)
                  Text('Tiempo estimado: ${envio.tiempoEstimadoMin} minutos'),
                const SizedBox(height: 24),
                Text(
                  'Línea de seguimiento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildTimeline(envio),
                const SizedBox(height: 16),
                if ((envio.notas ?? '').isNotEmpty) ...[
                  Text(
                    'Notas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(envio.notas!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(Envio envio) {
    // Estados posibles en orden lógico
    const estados = [
      'EN ESPERA ASIG',
      'ASIGNADO',
      'EN RUTA',
      'ENTREGADO',
    ];

    int currentIndex = estados.indexWhere((e) => e == envio.estatus);
    if (currentIndex == -1) {
      currentIndex = 0;
    }

    return Column(
      children: List.generate(estados.length, (index) {
        final estado = estados[index];
        final completed = index <= currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: completed ? Colors.green : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                if (index < estados.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: completed ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(estado),
              ),
            ),
          ],
        );
      }),
    );
  }
}
