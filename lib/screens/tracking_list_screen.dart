import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/envio.dart';
import '../providers/auth_provider.dart';

class TrackingListScreen extends StatefulWidget {
  const TrackingListScreen({super.key});

  @override
  State<TrackingListScreen> createState() => _TrackingListScreenState();
}

class _TrackingListScreenState extends State<TrackingListScreen> {
  Future<List<Envio>>? _futureEnvios;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _futureEnvios ??= _loadEnvios();
  }

  Future<List<Envio>> _loadEnvios() async {
    final auth = context.read<AuthProvider>();
    final clienteId = auth.user?.clienteId ?? 0;
    if (clienteId == 0) {
      return [];
    }

    try {
      final dio = auth.apiService.dio;
      final response = await dio.get('/Seguimiento/envios/cliente/$clienteId');
      final data = response.data;
      if (data is List) {
        return data.map((e) => Envio.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is Map<String, dynamic>) {
        final list = data['items'] ?? data['data'] ?? data['envios'] ?? data['resultado'];
        if (list is List) {
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => Envio.fromJson(e))
              .toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error obteniendo envios seguimiento: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de envíos'),
      ),
      body: FutureBuilder<List<Envio>>(
        future: _futureEnvios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar envíos: ${snapshot.error}'),
            );
          }

          final envios = snapshot.data ?? [];
          if (envios.isEmpty) {
            return const Center(
              child: Text('Aún no tienes envíos registrados.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: envios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = envios[index];

              final direccion = [
                e.direccionLinea1 ?? '',
                e.direccionLinea2 ?? '',
                e.ciudad ?? '',
                e.estado ?? '',
              ].where((x) => x.trim().isNotEmpty).join(', ');

              final fecha = e.fechaCreacion != null
                  ? '${e.fechaCreacion!.day.toString().padLeft(2, '0')}/'
                      '${e.fechaCreacion!.month.toString().padLeft(2, '0')}/'
                      '${e.fechaCreacion!.year}'
                  : '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    direccion.isEmpty ? 'Envío #${e.envioId}' : direccion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [fecha, e.estatus].where((x) => x.isNotEmpty).join(' · '),
                  ),
                  trailing: e.tiempoEstimadoMin != null
                      ? Text('${e.tiempoEstimadoMin} min')
                      : null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/tracking-detail',
                      arguments: {'envioId': e.envioId},
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
