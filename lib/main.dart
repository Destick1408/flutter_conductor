import 'package:flutter/material.dart';
import 'package:flutter_conductor/pages/login_page.dart';
import 'package:flutter_conductor/pages/map_page.dart';
import 'package:flutter_conductor/pages/history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <- obligatorio antes de usar plugins
  // cualquier inicialización asíncrona aquí si hace falta
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ivancar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
      // Rutas nombradas; la app inicia en el login
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/map': (context) => const MapPage(),
        '/history': (context) => const HistoryPage(),
      },
    );
  }
}
