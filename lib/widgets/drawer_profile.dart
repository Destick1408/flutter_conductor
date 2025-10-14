import 'package:flutter/material.dart';

class DrawerProfile extends StatelessWidget {
  final String? username;
  final String? nombre;
  final String? apellido;
  final String? avatarUrl;

  const DrawerProfile({
    super.key,
    this.username,
    this.nombre,
    this.apellido,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial'),
            onTap: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Ofertas'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.card_travel),
            title: const Text('Voucher'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('Crear Servicio'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock_clock_rounded),
            title: const Text('Para Reservar'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
