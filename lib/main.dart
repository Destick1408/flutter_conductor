import 'package:flutter/material.dart';
import 'package:flutter_conductor/pages/login_page.dart';
import 'package:flutter_conductor/pages/map_page.dart';
import 'package:flutter_conductor/pages/history_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- añadido

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <- obligatorio antes de usar plugins

  // Cargar .env antes de usar AuthApi o cualquier código que lea dotenv.env
  try {
    await dotenv.load(fileName: ".env");
    print('dotenv loaded: API_BASE_URL=${dotenv.env['API_BASE_URL']}');
  } catch (e) {
    print('dotenv load failed: $e');
  }

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
