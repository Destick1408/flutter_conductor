import 'package:flutter/material.dart';
import '../api/auth.dart'; // <-- nuevo import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // Nuevo: estado de carga para el botón
  bool _isLoading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    final username = _userController.text.trim();
    final password = _passController.text;
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario y contraseña requeridos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ok = await AuthApi.login(username, password);

      if (!mounted) return;

      if (ok) {
        Navigator.pushReplacementNamed(context, '/map');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login fallido')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          child: Column(
            // columna principal
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGO DE EMPRESA',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text('Usuario:', style: Theme.of(context).textTheme.bodyMedium),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa tu usuario',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contraseña:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa tu contraseña',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _onLoginPressed,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Procesando...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      : Text(
                          'Iniciar Sesión',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
