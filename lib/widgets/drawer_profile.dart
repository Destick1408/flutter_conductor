import 'package:flutter/material.dart';
import 'package:flutter_conductor/models/user.dart';
import 'package:flutter_conductor/widgets/user_info.dart';

class DrawerProfile extends StatelessWidget {
  final User? user;

  const DrawerProfile({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.yellow,
            width: double.infinity,
            child: UserInfo(user: user),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial'),
            onTap: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Ofertas'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_travel),
            title: const Text('Voucher'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('Crear Servicio'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_clock_rounded),
            title: const Text('Para Reservar'),
            onTap: () {},
          ),
          const Divider(),
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
