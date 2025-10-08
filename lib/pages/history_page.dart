import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  final List<Map<String, String>> _mockHistory = const [
    {'title': 'Viaje al centro', 'subtitle': '12/09/2025 — 09:30'},
    {'title': 'Entrega paquete', 'subtitle': '11/09/2025 — 16:10'},
    {'title': 'Recogida cliente', 'subtitle': '08/09/2025 — 19:45'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _mockHistory.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = _mockHistory[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(item['title']!),
            subtitle: Text(item['subtitle']!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Detalle: ${item['title']}')),
              );
            },
          );
        },
      ),
    );
  }
}