import 'package:flutter/material.dart';
import '../api/conductor.dart';
import '../models/service.dart';
import 'service_detail_page.dart'; // <-- import añadido

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Service>> _futureServices;

  @override
  void initState() {
    super.initState();
    _futureServices = ConductorApi.fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial'), centerTitle: true),
      body: FutureBuilder<List<Service>>(
        future: _futureServices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return const Center(child: Text('No hay registros'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final s = services[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title:
                    Text('${s.cliente?.nombreCompleto ?? 'Cliente'} — ${s.estado}'),
                subtitle: Text(
                  '${s.origen?.direccion ?? 'Origen'}\n→ ${s.destino?.direccion ?? 'Destino'}\n${s.fechaSolicitud}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailPage(service: s),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
